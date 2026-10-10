-- FireStation reports.
-- SQLite has no stored procedures, so this file plays that role: a set of
-- named queries you can run one at a time (Ctrl+Enter in DBeaver) or all
-- together (Alt+X). Each query starts with a "-- name:" line.
-- Queries that use :on_date ask for a date such as 2026-08-14.

-- name: monthly_summary
-- Responses per month, split by type.
SELECT
    strftime('%Y-%m', date)                          AS month,
    COUNT(*)                                         AS total,
    SUM(CASE WHEN type = 'fire' THEN 1 ELSE 0 END)    AS fire,
    SUM(CASE WHEN type = 'medical' THEN 1 ELSE 0 END) AS medical,
    SUM(CASE WHEN type = 'rescue' THEN 1 ELSE 0 END)  AS rescue,
    SUM(CASE WHEN type NOT IN ('fire', 'medical', 'rescue') THEN 1 ELSE 0 END) AS other
FROM responses
GROUP BY month
ORDER BY month;

-- name: equipment_usage
-- How many calls each piece of equipment went out on (zero included).
SELECT
    e.name,
    e.type,
    COUNT(re.response_id) AS times_used
FROM equipment AS e
LEFT JOIN response_equipment AS re ON re.equipment_id = e.id
GROUP BY e.id, e.name, e.type
ORDER BY times_used DESC, e.name;

-- name: not_ready
-- Everything the chief cannot send out right now.
SELECT name, status, last_checked, latest_maintenance, reason
FROM readiness_view
WHERE readiness = 'not ready'
ORDER BY name;

-- name: equipment_on_date
-- Equipment used on each call on a given date.
SELECT
    r.date,
    r.address,
    r.type AS call_type,
    e.name AS equipment
FROM responses AS r
INNER JOIN response_equipment AS re ON re.response_id = r.id
INNER JOIN equipment AS e ON e.id = re.equipment_id
WHERE r.date = :on_date
ORDER BY r.id, e.name;

-- name: crew_on_date
-- Crew who answered each call on a given date.
SELECT
    r.date,
    r.address,
    c.name AS crew_member,
    c.role
FROM responses AS r
INNER JOIN response_crew AS rc ON rc.response_id = r.id
INNER JOIN crew_members AS c ON c.id = rc.member_id
WHERE r.date = :on_date
ORDER BY r.id, c.name;

-- name: responses_by_type
-- Total responses of each type, busiest first.
SELECT type, COUNT(*) AS responses
FROM responses
GROUP BY type
ORDER BY responses DESC, type;

-- name: not_checked_30_days
-- Equipment never checked, or last checked more than 30 days ago.
SELECT
    name,
    type,
    last_checked,
    CAST(julianday('now', 'start of day') - julianday(last_checked) AS INTEGER) AS days_since_check
FROM equipment
WHERE last_checked IS NULL
   OR last_checked < date('now', '-30 days')
ORDER BY last_checked IS NOT NULL, last_checked;

-- name: status_history
-- Every status change the trigger has recorded, newest first.
SELECT s.id, e.name, s.old_status, s.new_status, s.changed_at
FROM status_change_log AS s
INNER JOIN equipment AS e ON e.id = s.equipment_id
ORDER BY s.id DESC;