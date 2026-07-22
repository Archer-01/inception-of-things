#!/usr/bin/env python3
import json, subprocess, sys, os

GITLAB_PORT = os.environ.get("BONUS_GITLAB_PORT", "8080")
TOKEN_FILE = os.path.expanduser("~/.gitlab-token")
REPO_NAME = sys.argv[1] if len(sys.argv) > 1 else "stamim-config"
SED_EXPR = sys.argv[2] if len(sys.argv) > 2 else None
ACTION = sys.argv[3] if len(sys.argv) > 3 else "update"
CONFS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "confs")

with open(TOKEN_FILE) as f:
    TOKEN = f.read().strip()

subprocess.run(["kubectl", "delete", "pod", "git-push", "-n", "gitlab", "--ignore-not-found"],
    capture_output=True)

API = f"http://localhost:{GITLAB_PORT}/api/v4"
GITLAB_SVC = "gitlab-webservice-default.gitlab.svc:8181"
REPO_URL = f"http://oauth2:{TOKEN}@{GITLAB_SVC}/root/{REPO_NAME}.git"

def api_call(method, path, data=None):
    cmd = ["curl", "-sf", "-X", method, f"{API}{path}", "-H", f"PRIVATE-TOKEN: {TOKEN}", "-H", "Content-Type: application/json"]
    if data:
        cmd.extend(["-d", json.dumps(data)])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return None
    try:
        return json.loads(r.stdout)
    except:
        return r.stdout

def push_via_pod(git_cmds):
    subprocess.run(["kubectl", "run", "git-push", "-n", "gitlab",
        "--image=alpine/git", "--restart=Never",
        "--command", "--", "/bin/sh", "-c", "sleep 3600"],
        capture_output=True, check=True)
    subprocess.run(["kubectl", "wait", "--for=condition=ready",
        "pod/git-push", "-n", "gitlab", "--timeout=30s"],
        capture_output=True)

    for path, src in files.items():
        subprocess.run(["kubectl", "cp", src, f"gitlab/git-push:/tmp/{os.path.basename(src)}"],
            capture_output=True, check=True)

    result = subprocess.run(
        ["kubectl", "exec", "-n", "gitlab", "git-push", "--", "/bin/sh", "-c", " && ".join(git_cmds)],
        capture_output=True, text=True)
    print(result.stdout)

    subprocess.run(["kubectl", "delete", "pod", "git-push", "-n", "gitlab", "--ignore-not-found"],
        capture_output=True)

    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

files = {
    "k8s/deployment.yaml": os.path.join(CONFS_DIR, "deployment.yaml"),
    "k8s/service.yaml": os.path.join(CONFS_DIR, "service.yaml"),
}

repos = api_call("GET", f"/projects?search={REPO_NAME}")
if not repos:
    print(f"Error: project {REPO_NAME} not found", file=sys.stderr)
    sys.exit(1)
repo_id = repos[0]["id"]
print(f"Project ID: {repo_id}")

branches = api_call("GET", f"/projects/{repo_id}/repository/branches") or []
cp_cmds = [f"cp /tmp/{os.path.basename(src)} {path}" for path, src in files.items()]

if not branches:
    print("Empty repo, pushing via in-cluster git pod...")
    git_cmds = [
        "cd /tmp && rm -rf repo && mkdir repo && cd repo",
        "git init -b main",
        f"git config user.email 'stamim@local'",
        "git config user.name 'stamim'",
        "mkdir -p k8s",
        *cp_cmds,
        "git add .",
        "git commit -m 'initial config'",
        f"git remote add origin {REPO_URL}",
        "git push -u origin main --force 2>&1",
    ]
else:
    print("Repo has commits, updating via in-cluster git pod...")
    sed_cmd = [f"sed -i '{SED_EXPR}' k8s/deployment.yaml"] if SED_EXPR else []
    cp_or_sed = sed_cmd if SED_EXPR else cp_cmds
    commit_msg = ACTION if SED_EXPR else "update config"
    git_cmds = [
        "cd /tmp && rm -rf repo && mkdir repo && cd repo",
        f"git clone {REPO_URL} .",
        "git config user.email 'stamim@local'",
        "git config user.name 'stamim'",
        "mkdir -p k8s",
        *cp_or_sed,
        "git add .",
        f"git commit -m '{commit_msg}' || echo 'No changes'",
        "git push origin main 2>&1",
    ]

push_via_pod(git_cmds)
print("Done" if branches else "Pushed via in-cluster git pod")
