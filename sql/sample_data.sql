-- FireStation sample data.
-- Equipment check dates are relative to today, so the readiness picture
-- looks the same whenever the database is built. Response dates are
-- fixed calendar dates, so the response reports never change.

INSERT INTO equipment (id, name, type, status, last_checked) VALUES
    (1,  'Engine 1 Pumper',  'apparatus',   'in_service',     date('now', '-3 days')),
    (2,  'Ladder 1',         'apparatus',   'in_service',     date('now', '-10 days')),
    (3,  'Rescue 1',         'apparatus',   'under_repair',   date('now', '-5 days')),
    (4,  'SCBA Pack A',      'breathing',   'in_service',     date('now', '-2 days')),
    (5,  'SCBA Pack B',      'breathing',   'out_of_service', date('now', '-20 days')),
    (6,  'Thermal Camera',   'electronics', 'in_service',     date('now', '-45 days')),
    (7,  'Hydraulic Cutter', 'rescue tool', 'in_service',     date('now', '-12 days')),
    (8,  'Portable Pump',    'pump',        'in_service',     date('now', '-60 days')),
    (9,  'Defibrillator',    'medical',     'in_service',     date('now', '-1 days')),
    (10, 'Hose Bundle 3',    'hose',        'in_service',     NULL),
    (11, 'Radio Set 4',      'comms',       'in_service',     date('now', '-25 days'));

INSERT INTO crew_members (id, name, role) VALUES
    (1, 'Dana Reyes',  'chief'),
    (2, 'Sam Okafor',  'captain'),
    (3, 'Priya Nair',  'firefighter'),
    (4, 'Tom Becker',  'driver'),
    (5, 'Lee Wong',    'emt');

INSERT INTO responses (id, date, address, type) VALUES
    (1,  '2022-11-03', '14 Mill Lane',      'fire'),
    (2,  '2023-02-18', 'Route 9 mile 4',    'rescue'),
    (3,  '2023-06-30', '7 Oak Street',      'medical'),
    (4,  '2026-07-04', 'Riverside Park',    'fire'),
    (5,  '2026-07-19', '22 Elm Road',       'medical'),
    (6,  '2026-07-19', '3 Station Hill',    'alarm'),
    (7,  '2026-08-02', 'Route 9 mile 12',   'rescue'),
    (8,  '2026-08-14', '101 Market Square', 'fire'),
    (9,  '2026-08-14', '45 Birch Avenue',   'medical'),
    (10, '2026-08-27', 'Old Quarry Road',   'hazmat'),
    (11, '2026-09-05', '8 Cedar Court',     'medical'),
    (12, '2026-09-21', '60 Harbor Road',    'fire'),
    (13, '2026-09-30', 'County School',     'alarm');

INSERT INTO response_equipment (response_id, equipment_id) VALUES
    (1, 1), (1, 2), (1, 4),
    (2, 3), (2, 7),
    (3, 9),
    (4, 1), (4, 4), (4, 6),
    (5, 9),
    (6, 1), (6, 11),
    (7, 3), (7, 7), (7, 11),
    (8, 1), (8, 2), (8, 4), (8, 5), (8, 6),
    (9, 9),
    (10, 1), (10, 8), (10, 11),
    (11, 9),
    (12, 1), (12, 2), (12, 4), (12, 6),
    (13, 1), (13, 11);

INSERT INTO response_crew (response_id, member_id) VALUES
    (1, 1), (1, 3), (1, 4),
    (2, 2), (2, 4),
    (3, 5),
    (4, 2), (4, 3), (4, 4),
    (5, 5),
    (6, 2), (6, 4),
    (7, 1), (7, 3), (7, 4),
    (8, 1), (8, 2), (8, 3), (8, 4),
    (9, 5),
    (10, 1), (10, 2), (10, 4),
    (11, 3), (11, 5),
    (12, 2), (12, 3), (12, 4),
    (13, 4);

INSERT INTO maintenance_log (equipment_id, date, action, notes) VALUES
    (1,  date('now', '-3 days'),  'check',   'Pump pressure and lights OK'),
    (2,  date('now', '-10 days'), 'check',   'Aerial ladder extended and inspected'),
    (3,  date('now', '-5 days'),  'repair',  'Hydraulic leak, sent to workshop'),
    (4,  date('now', '-2 days'),  'check',   'Cylinder at full pressure'),
    (5,  date('now', '-20 days'), 'check',   'Face seal cracked, removed from service'),
    (6,  date('now', '-45 days'), 'check',   'Battery replaced'),
    (6,  date('now', '-90 days'), 'service', 'Firmware update'),
    (7,  date('now', '-12 days'), 'check',   'Blades sharp, hoses intact'),
    (8,  date('now', '-60 days'), 'service', 'Oil changed'),
    (9,  date('now', '-1 days'),  'check',   'Pads in date, self-test passed'),
    (11, date('now', '-25 days'), 'check',   'All channels tested');