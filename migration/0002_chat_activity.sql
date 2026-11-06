CREATE TABLE IF NOT EXISTS mcs_activity (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  name TEXT NOT NULL,
  event TEXT NOT NULL,
  detail TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (room_id) REFERENCES mcs_rooms(room_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_mcs_activity_room_time ON mcs_activity(room_id, created_at);
