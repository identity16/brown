CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ts TEXT NOT NULL,
  kind TEXT NOT NULL,
  name TEXT NOT NULL,
  plugin_version TEXT NOT NULL,
  os TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_events_received_at ON events(received_at);
CREATE INDEX IF NOT EXISTS idx_events_kind_name ON events(kind, name);
