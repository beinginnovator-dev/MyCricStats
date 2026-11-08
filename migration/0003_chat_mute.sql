ALTER TABLE mcs_members ADD COLUMN muted INTEGER NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_mcs_members_room_muted ON mcs_members(room_id, muted);
