-- FireStation logic: triggers and the readiness view.

-- Every real status change on a piece of equipment is written to
-- status_change_log. UPDATE OF status means updates that do not set
-- status never fire it; the WHEN clause also skips updates that set
-- status to the value it already has.
CREATE TRIGGER trg_equipment_status_change
AFTER UPDATE OF status ON equipment
FOR EACH ROW
WHEN OLD.status IS NOT NEW.status
BEGIN
    INSERT INTO status_change_log (equipment_id, old_status, new_status, changed_at)
    VALUES (NEW.id, OLD.status, NEW.status, datetime('now'));
END;

-- Logging a 'check' in maintenance_log moves equipment.last_checked
-- forward. A check entered late (older than the current value) never
-- moves it backwards.
CREATE TRIGGER trg_maintenance_check
AFTER INSERT ON maintenance_log
FOR EACH ROW
WHEN NEW.action = 'check'
BEGIN
    UPDATE equipment
    SET last_checked = NEW.date
    WHERE id = NEW.equipment_id
      AND (last_checked IS NULL OR last_checked < NEW.date);
END;

-- One row per piece of equipment: its latest maintenance date and
-- whether it is ready. Ready means in service AND checked in the last
-- 30 days. Anything else is 'not ready', with the reason spelled out.
CREATE VIEW readiness_view AS
SELECT
    e.id,
    e.name,
    e.type,
    e.status,
    e.last_checked,
    m.latest_maintenance,
    CASE
        WHEN e.status = 'in_service'
         AND e.last_checked >= date('now', '-30 days') THEN 'ready'
        ELSE 'not ready'
    END AS readiness,
    CASE
        WHEN e.status <> 'in_service' THEN e.status
        WHEN e.last_checked IS NULL THEN 'never checked'
        WHEN e.last_checked < date('now', '-30 days') THEN 'check overdue'
        ELSE ''
    END AS reason
FROM equipment AS e
LEFT JOIN (
    SELECT equipment_id, MAX(date) AS latest_maintenance
    FROM maintenance_log
    GROUP BY equipment_id
) AS m ON m.equipment_id = e.id;