-- FireStation performance and health checks.
-- Run each named query on its own, the same way as the reports.

-- name: analyze
-- Refresh the statistics the query planner uses to choose indexes.
ANALYZE;

-- name: plan_responses_by_date
-- Should say SEARCH ... USING INDEX idx_responses_date.
EXPLAIN QUERY PLAN
SELECT id, date, address, type
FROM responses
WHERE date BETWEEN '2026-08-01' AND '2026-08-31';

-- name: plan_equipment_by_status
-- Should say SEARCH ... USING INDEX idx_equipment_status.
EXPLAIN QUERY PLAN
SELECT id, name
FROM equipment
WHERE status = 'out_of_service';

-- name: integrity_check
-- Prints a single row 'ok' when the database file is healthy.
PRAGMA integrity_check;

-- name: row_counts
-- How many rows each table holds.
SELECT 'equipment' AS table_name, COUNT(*) AS row_count FROM equipment
UNION ALL SELECT 'crew_members', COUNT(*) FROM crew_members
UNION ALL SELECT 'responses', COUNT(*) FROM responses
UNION ALL SELECT 'response_equipment', COUNT(*) FROM response_equipment
UNION ALL SELECT 'response_crew', COUNT(*) FROM response_crew
UNION ALL SELECT 'maintenance_log', COUNT(*) FROM maintenance_log
UNION ALL SELECT 'status_change_log', COUNT(*) FROM status_change_log
UNION ALL SELECT 'responses_archive', COUNT(*) FROM responses_archive;