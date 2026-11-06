PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS mcs_rooms (
  room_id TEXT PRIMARY KEY,
  owner_hash TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS mcs_members (
  room_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at INTEGER NOT NULL,
  last_seen INTEGER NOT NULL,
  blocked INTEGER NOT NULL DEFAULT 0,
  removed INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (room_id, member_id),
  FOREIGN KEY (room_id) REFERENCES mcs_rooms(room_id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS mcs_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  name TEXT NOT NULL,
  text TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'chat',
  created_at INTEGER NOT NULL,
  edited INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (room_id) REFERENCES mcs_rooms(room_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_mcs_messages_room_time ON mcs_messages(room_id, created_at);
CREATE INDEX IF NOT EXISTS idx_mcs_members_room_seen ON mcs_members(room_id, last_seen);
