BEGIN TRANSACTION;
CREATE TABLE equipment (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,
    type         TEXT NOT NULL,
    status       TEXT NOT NULL DEFAULT 'in_service'
                 CHECK (status IN ('in_service', 'out_of_service', 'under_repair')),
    last_checked TEXT CHECK (date(last_checked) IS last_checked)
);
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (1, 'Engine 1 Pumper', 'apparatus', 'in_service', '2026-10-07');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (2, 'Ladder 1', 'apparatus', 'in_service', '2026-09-30');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (3, 'Rescue 1', 'apparatus', 'under_repair', '2026-10-05');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (4, 'SCBA Pack A', 'breathing', 'in_service', '2026-10-08');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (5, 'SCBA Pack B', 'breathing', 'out_of_service', '2026-09-20');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (6, 'Thermal Camera', 'electronics', 'out_of_service', '2026-08-26');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (7, 'Hydraulic Cutter', 'rescue tool', 'in_service', '2026-09-28');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (8, 'Portable Pump', 'pump', 'in_service', '2026-10-10');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (9, 'Defibrillator', 'medical', 'in_service', '2026-10-09');
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (10, 'Hose Bundle 3', 'hose', 'in_service', NULL);
INSERT INTO equipment (id, name, type, status, last_checked) VALUES (11, 'Radio Set 4', 'comms', 'in_service', '2026-09-15');
CREATE INDEX idx_equipment_status ON equipment (status);
CREATE TABLE crew_members (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT NOT NULL
);
INSERT INTO crew_members (id, name, role) VALUES (1, 'Dana Reyes', 'chief');
INSERT INTO crew_members (id, name, role) VALUES (2, 'Sam Okafor', 'captain');
INSERT INTO crew_members (id, name, role) VALUES (3, 'Priya Nair', 'firefighter');
INSERT INTO crew_members (id, name, role) VALUES (4, 'Tom Becker', 'driver');
INSERT INTO crew_members (id, name, role) VALUES (5, 'Lee Wong', 'emt');
CREATE TABLE responses (
    id      INTEGER PRIMARY KEY,
    date    TEXT NOT NULL CHECK (date(date) IS date),
    address TEXT NOT NULL,
    type    TEXT NOT NULL
            CHECK (type IN ('fire', 'medical', 'rescue', 'hazmat', 'alarm', 'other'))
);
INSERT INTO responses (id, date, address, type) VALUES (4, '2026-07-04', 'Riverside Park', 'fire');
INSERT INTO responses (id, date, address, type) VALUES (5, '2026-07-19', '22 Elm Road', 'medical');
INSERT INTO responses (id, date, address, type) VALUES (6, '2026-07-19', '3 Station Hill', 'alarm');
INSERT INTO responses (id, date, address, type) VALUES (7, '2026-08-02', 'Route 9 mile 12', 'rescue');
INSERT INTO responses (id, date, address, type) VALUES (8, '2026-08-14', '101 Market Square', 'fire');
INSERT INTO responses (id, date, address, type) VALUES (9, '2026-08-14', '45 Birch Avenue', 'medical');
INSERT INTO responses (id, date, address, type) VALUES (10, '2026-08-27', 'Old Quarry Road', 'hazmat');
INSERT INTO responses (id, date, address, type) VALUES (11, '2026-09-05', '8 Cedar Court', 'medical');
INSERT INTO responses (id, date, address, type) VALUES (12, '2026-09-21', '60 Harbor Road', 'fire');
INSERT INTO responses (id, date, address, type) VALUES (13, '2026-09-30', 'County School', 'alarm');
CREATE INDEX idx_responses_date ON responses (date);
CREATE TABLE response_equipment (
    response_id  INTEGER NOT NULL REFERENCES responses (id),
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    PRIMARY KEY (response_id, equipment_id)
);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (4, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (4, 4);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (4, 6);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (5, 9);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (6, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (6, 11);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (7, 3);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (7, 7);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (7, 11);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (8, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (8, 2);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (8, 4);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (8, 5);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (8, 6);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (9, 9);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (10, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (10, 8);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (10, 11);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (11, 9);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (12, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (12, 2);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (12, 4);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (12, 6);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (13, 1);
INSERT INTO response_equipment (response_id, equipment_id) VALUES (13, 11);
CREATE INDEX idx_response_equipment_equipment ON response_equipment (equipment_id);
CREATE TABLE response_crew (
    response_id INTEGER NOT NULL REFERENCES responses (id),
    member_id   INTEGER NOT NULL REFERENCES crew_members (id),
    PRIMARY KEY (response_id, member_id)
);
INSERT INTO response_crew (response_id, member_id) VALUES (4, 2);
INSERT INTO response_crew (response_id, member_id) VALUES (4, 3);
INSERT INTO response_crew (response_id, member_id) VALUES (4, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (5, 5);
INSERT INTO response_crew (response_id, member_id) VALUES (6, 2);
INSERT INTO response_crew (response_id, member_id) VALUES (6, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (7, 1);
INSERT INTO response_crew (response_id, member_id) VALUES (7, 3);
INSERT INTO response_crew (response_id, member_id) VALUES (7, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (8, 1);
INSERT INTO response_crew (response_id, member_id) VALUES (8, 2);
INSERT INTO response_crew (response_id, member_id) VALUES (8, 3);
INSERT INTO response_crew (response_id, member_id) VALUES (8, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (9, 5);
INSERT INTO response_crew (response_id, member_id) VALUES (10, 1);
INSERT INTO response_crew (response_id, member_id) VALUES (10, 2);
INSERT INTO response_crew (response_id, member_id) VALUES (10, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (11, 3);
INSERT INTO response_crew (response_id, member_id) VALUES (11, 5);
INSERT INTO response_crew (response_id, member_id) VALUES (12, 2);
INSERT INTO response_crew (response_id, member_id) VALUES (12, 3);
INSERT INTO response_crew (response_id, member_id) VALUES (12, 4);
INSERT INTO response_crew (response_id, member_id) VALUES (13, 4);
CREATE TABLE maintenance_log (
    id           INTEGER PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    date         TEXT NOT NULL CHECK (date(date) IS date),
    action       TEXT NOT NULL CHECK (action IN ('check', 'service', 'repair', 'replace')),
    notes        TEXT
);
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (1, 1, '2026-10-07', 'check', 'Pump pressure and lights OK');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (2, 2, '2026-09-30', 'check', 'Aerial ladder extended and inspected');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (3, 3, '2026-10-05', 'repair', 'Hydraulic leak, sent to workshop');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (4, 4, '2026-10-08', 'check', 'Cylinder at full pressure');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (5, 5, '2026-09-20', 'check', 'Face seal cracked, removed from service');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (6, 6, '2026-08-26', 'check', 'Battery replaced');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (7, 6, '2026-07-12', 'service', 'Firmware update');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (8, 7, '2026-09-28', 'check', 'Blades sharp, hoses intact');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (9, 8, '2026-08-11', 'service', 'Oil changed');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (10, 9, '2026-10-09', 'check', 'Pads in date, self-test passed');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (11, 11, '2026-09-15', 'check', 'All channels tested');
INSERT INTO maintenance_log (id, equipment_id, date, action, notes) VALUES (12, 8, '2026-10-10', 'check', 'Pump primed and tested');
CREATE INDEX idx_maintenance_equipment_date ON maintenance_log (equipment_id, date);
CREATE TABLE status_change_log (
    id           INTEGER PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment (id),
    old_status   TEXT NOT NULL,
    new_status   TEXT NOT NULL,
    changed_at   TEXT NOT NULL
);
INSERT INTO status_change_log (id, equipment_id, old_status, new_status, changed_at) VALUES (1, 6, 'in_service', 'out_of_service', '2026-10-10 11:01:16');
CREATE TABLE responses_archive (
    id          INTEGER PRIMARY KEY,
    date        TEXT NOT NULL,
    address     TEXT NOT NULL,
    type        TEXT NOT NULL,
    archived_at TEXT NOT NULL
);
INSERT INTO responses_archive (id, date, address, type, archived_at) VALUES (1, '2022-11-03', '14 Mill Lane', 'fire', '2026-10-10 11:18:15');
INSERT INTO responses_archive (id, date, address, type, archived_at) VALUES (2, '2023-02-18', 'Route 9 mile 4', 'rescue', '2026-10-10 11:18:15');
INSERT INTO responses_archive (id, date, address, type, archived_at) VALUES (3, '2023-06-30', '7 Oak Street', 'medical', '2026-10-10 11:18:15');
CREATE TABLE response_equipment_archive (
    response_id  INTEGER NOT NULL,
    equipment_id INTEGER NOT NULL,
    PRIMARY KEY (response_id, equipment_id)
);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (1, 1);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (1, 2);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (1, 4);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (2, 3);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (2, 7);
INSERT INTO response_equipment_archive (response_id, equipment_id) VALUES (3, 9);
CREATE TABLE response_crew_archive (
    response_id INTEGER NOT NULL,
    member_id   INTEGER NOT NULL,
    PRIMARY KEY (response_id, member_id)
);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (1, 1);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (1, 3);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (1, 4);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (2, 2);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (2, 4);
INSERT INTO response_crew_archive (response_id, member_id) VALUES (3, 5);
COMMIT;
