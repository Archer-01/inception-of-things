## Summary

> _One or two sentences. What does this PR do and why?_

✏️ ...

**Type of change:**
- [ ] New feature
- [ ] Bug fix
- [ ] Refactor (no behavior change)
- [ ] Breaking change
- [ ] Documentation
- [ ] Build / CI
- [ ] Chore / cleanup

---

## Motivation & Context

> _Why is this change needed? Link related issues, discussions, or previous PRs if any._

✏️ ...

Closes #<!-- issue number, if applicable -->

---

## What Changed

> _A concise description of the implementation. Focus on decisions, not a line-by-line walkthrough._

---

## New Components or Structure

> _Skip if no new files, classes, modules, or directories are introduced._

| Path | Role | Notes |
|---|---|---|
| `[src/module/ClassName.cpp]` | `[what it does]` | `[optional context]` |

**Design rationale:**
> _Why this structure? What alternatives were considered?_

---

## How to Build & Test

```bash
# Get the branch
git fetch origin
git checkout [branch-name]

# Build
make / cmake --build . / npm install && npm run build

# Run
./program [args]
```

**Requirements:**
- OS: <!-- Linux / macOS / both -->
- Compiler / runtime: <!-- e.g. gcc with -Wall -Wextra -Werror, Node 20, Python 3.11 -->
- Dependencies: <!-- anything to install first -->

**Relevant test cases:**
```bash
echo "some input" | ./program
./program "" to test empty input
./program < /dev/null to test EOF
```

---

## Checklist

- [ ] Builds without warnings
- [ ] No memory leaks / resource leaks
- [ ] Edge cases handled
- [ ] No unrelated changes included
- [ ] Branch is up to date with `main`
- [ ] Self-reviewed before requesting review

---

## Reviewer Notes

> _What do you want feedback on specifically? Flag anything uncertain, experimental, or worth a second opinion._

---

## Follow-up

> _Anything intentionally left out, known limitations, or planned next PRs._

---

<!--
  TEMPLATE MAINTENANCE
  If something about the project has changed (build steps, structure conventions,
  review focus), update this file in a separate commit or note it here.
  Keep this template in sync with the actual state of the project.
-->
