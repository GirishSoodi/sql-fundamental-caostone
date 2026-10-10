-- FireStation archive step: move responses older than two years, with
-- their equipment and crew rows, into the *_archive tables.
-- The ids to move are captured ONCE in a temporary table, so every
-- statement below works on exactly the same set of responses even if the
-- clock passes midnight while the script runs.

BEGIN TRANSACTION;

DROP TABLE IF EXISTS temp.archive_ids;
CREATE TEMP TABLE archive_ids AS
SELECT id FROM responses WHERE date < date('now', '-2 years');

INSERT INTO responses_archive (id, date, address, type, archived_at)
SELECT id, date, address, type, datetime('now')
FROM responses
WHERE id IN (SELECT id FROM archive_ids);

INSERT INTO response_equipment_archive (response_id, equipment_id)
SELECT response_id, equipment_id
FROM response_equipment
WHERE response_id IN (SELECT id FROM archive_ids);

INSERT INTO response_crew_archive (response_id, member_id)
SELECT response_id, member_id
FROM response_crew
WHERE response_id IN (SELECT id FROM archive_ids);

-- Child rows first, so the foreign keys never point at a missing response.
DELETE FROM response_equipment WHERE response_id IN (SELECT id FROM archive_ids);
DELETE FROM response_crew WHERE response_id IN (SELECT id FROM archive_ids);
DELETE FROM responses WHERE id IN (SELECT id FROM archive_ids);

DROP TABLE temp.archive_ids;

COMMIT;