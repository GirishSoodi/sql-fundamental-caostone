-- FireStation schema: tables and indexes.
-- Dates are stored as TEXT in ISO format (YYYY-MM-DD) so they sort and
-- compare correctly and work with SQLite's date() function.
-- Date CHECKs use IS, not =: date('14/08/2026') is NULL, and a CHECK
-- whose result is NULL counts as passed, so = would let bad dates in.

PRAGMA foreign_keys = ON;

CREATE TABLE equipment (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,
    type         TEXT NOT NULL,
    status       TEXT NOT NULL DEFAULT 'in_service'
                 CHECK (status IN ('in_service', 'out_of_service', 'under_repair')),
    last_checked TEXT CHECK (date(last_checked) IS last_checked)
);

CREATE TABLE crew_members (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT NOT NULL
);

CREATE TABLE responses (
    id      INTEGER PRIMARY KEY,
    date    TEXT NOT NULL CHECK (date(date) IS date),
    address TEXT NOT NULL,
    type    TEXT NOT NULL
            CHECK (type IN ('fire', 'medical', 'rescue', 'hazmat', 'alarm', 'other'))
);

-- Which equipment went out on which call (many-to-many).
CREATE TABLE response_equipment (
    response_id  INTEGER NOT NULL REFERENCES responses (id),
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    PRIMARY KEY (response_id, equipment_id)
);

-- Which crew members answered which call (many-to-many).
CREATE TABLE response_crew (
    response_id INTEGER NOT NULL REFERENCES responses (id),
    member_id   INTEGER NOT NULL REFERENCES crew_members (id),
    PRIMARY KEY (response_id, member_id)
);

CREATE TABLE maintenance_log (
    id           INTEGER PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    date         TEXT NOT NULL CHECK (date(date) IS date),
    action       TEXT NOT NULL CHECK (action IN ('check', 'service', 'repair', 'replace')),
    notes        TEXT
);

-- Filled only by the trigger trg_equipment_status_change.
CREATE TABLE status_change_log (
    id           INTEGER PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    old_status   TEXT NOT NULL,
    new_status   TEXT NOT NULL,
    changed_at   TEXT NOT NULL
);

-- Archive tables: same columns as the live tables, no foreign keys,
-- plus the moment each response was archived.
CREATE TABLE responses_archive (
    id          INTEGER PRIMARY KEY,
    date        TEXT NOT NULL,
    address     TEXT NOT NULL,
    type        TEXT NOT NULL,
    archived_at TEXT NOT NULL
);

CREATE TABLE response_equipment_archive (
    response_id  INTEGER NOT NULL,
    equipment_id INTEGER NOT NULL,
    PRIMARY KEY (response_id, equipment_id)
);

CREATE TABLE response_crew_archive (
    response_id INTEGER NOT NULL,
    member_id   INTEGER NOT NULL,
    PRIMARY KEY (response_id, member_id)
);

-- Indexes that keep the reports fast.
CREATE INDEX idx_responses_date ON responses (date);
CREATE INDEX idx_equipment_status ON equipment (status);
CREATE INDEX idx_response_equipment_equipment ON response_equipment (equipment_id);
CREATE INDEX idx_maintenance_equipment_date ON maintenance_log (equipment_id, date);