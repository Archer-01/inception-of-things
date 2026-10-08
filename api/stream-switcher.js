function rewritePlaylistEntries(playlist, s3BaseUrl) {
  const normalizedBase = s3BaseUrl.replace(/\/$/, "");

  return playlist
    .split("\n")
    .map((line) => {
      const trimmed = line.trim();

      if (!trimmed || trimmed.startsWith("#") || /^https?:\/\//i.test(trimmed)) {
        return line;
      }

      return `${normalizedBase}/${trimmed.replace(/^\/+/, "")}`;
    })
    .join("\n");
}

export default async function handler(req, res) {
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  const source = req.query.source;
  const s3Bucket = process.env.AWS_S3_BUCKET;
  const awsRegion = process.env.AWS_REGION;

  if (!source || Array.isArray(source)) {
    return res.status(400).json({ error: "The source query param is required." });
  }

  if (!s3Bucket || !awsRegion) {
    return res.status(500).json({ error: "AWS_S3_BUCKET or AWS_REGION is not configured." });
  }

  const s3PlaylistBaseUrl = `https://${s3Bucket}.s3.${awsRegion}.amazonaws.com`;

  let sourceUrl;

  try {
    sourceUrl = new URL(source);
  } catch {
    return res.status(400).json({ error: "The source query param must be a valid URL." });
  }

  if (sourceUrl.protocol !== "https:") {
    return res.status(400).json({ error: "The source query param must use HTTPS." });
  }

  let upstream;

  try {
    upstream = await fetch(sourceUrl.toString());
  } catch {
    return res.status(502).json({ error: "Failed to reach upstream playlist." });
  }

  if (!upstream.ok) {
    return res.status(upstream.status).json({
      error: `Upstream playlist request failed with status ${upstream.status}.`,
    });
  }

  const body = await upstream.text();
  const rewrittenPlaylist = rewritePlaylistEntries(body, s3PlaylistBaseUrl);

  res.setHeader("Content-Type", "application/vnd.apple.mpegurl; charset=utf-8");
  res.setHeader("Cache-Control", "public, s-maxage=30, stale-while-revalidate=120");

  return res.status(200).send(rewrittenPlaylist);
}
