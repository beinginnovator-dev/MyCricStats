CREATE TABLE IF NOT EXISTS mcs_domestic_matches (
  match_id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'upcoming',
  updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mcs_domestic_updated ON mcs_domestic_matches(updated_at DESC);
