import sqlite3
import unittest

import db


class SchemaTest(unittest.TestCase):
    def setUp(self):
        self.conn = db.connect(":memory:")
        db.build_database(self.conn)

    def tearDown(self):
        self.conn.close()

    def scalar(self, sql, params=()):
        return self.conn.execute(sql, params).fetchone()[0]

    def test_all_tables_view_and_triggers_exist(self):
        names = {
            row[0]
            for row in self.conn.execute(
                "SELECT name FROM sqlite_master WHERE type IN ('table', 'view', 'trigger')"
            )
        }
        for expected in db.BACKUP_TABLES + [
            "readiness_view",
            "trg_equipment_status_change",
            "trg_maintenance_check",
        ]:
            self.assertIn(expected, names)

    def test_required_indexes_exist(self):
        indexes = {
            row[0]
            for row in self.conn.execute("SELECT name FROM sqlite_master WHERE type = 'index'")
        }
        self.assertIn("idx_responses_date", indexes)
        self.assertIn("idx_equipment_status", indexes)

    def test_sample_data_loaded(self):
        self.assertEqual(db.count_rows(self.conn, "equipment"), 11)
        self.assertEqual(db.count_rows(self.conn, "crew_members"), 5)
        self.assertEqual(db.count_rows(self.conn, "responses"), 13)
        self.assertEqual(db.count_rows(self.conn, "response_equipment"), 31)
        self.assertEqual(db.count_rows(self.conn, "maintenance_log"), 11)
        self.assertEqual(db.count_rows(self.conn, "status_change_log"), 0)

    def test_invalid_status_is_rejected(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.conn.execute("UPDATE equipment SET status = 'broken' WHERE id = 1")

    def test_badly_formatted_date_is_rejected(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.conn.execute(
                "INSERT INTO responses (date, address, type) VALUES ('14/08/2026', 'X', 'fire')"
            )

    def test_impossible_check_date_is_rejected(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.conn.execute("UPDATE equipment SET last_checked = '2026-13-45' WHERE id = 1")

    def test_foreign_key_blocks_unknown_equipment(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.conn.execute(
                "INSERT INTO response_equipment (response_id, equipment_id) VALUES (1, 999)"
            )

    def test_status_update_fires_trigger(self):
        db.set_status(self.conn, 6, "out_of_service")
        rows = self.conn.execute(
            "SELECT equipment_id, old_status, new_status, changed_at FROM status_change_log"
        ).fetchall()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][:3], (6, "in_service", "out_of_service"))
        self.assertIsNotNone(rows[0][3])

    def test_same_status_or_other_column_update_is_not_logged(self):
        db.set_status(self.conn, 1, "in_service")
        self.conn.execute("UPDATE equipment SET last_checked = date('now') WHERE id = 2")
        self.assertEqual(db.count_rows(self.conn, "status_change_log"), 0)

    def test_every_change_gets_its_own_row(self):
        db.set_status(self.conn, 3, "in_service")
        db.set_status(self.conn, 3, "out_of_service")
        rows = self.conn.execute(
            "SELECT old_status, new_status FROM status_change_log ORDER BY id"
        ).fetchall()
        self.assertEqual(
            rows,
            [("under_repair", "in_service"), ("in_service", "out_of_service")],
        )

    def test_set_status_unknown_id_raises(self):
        with self.assertRaises(ValueError):
            db.set_status(self.conn, 999, "in_service")

    def test_logged_check_moves_last_checked_forward(self):
        db.log_maintenance(self.conn, 8, "check", "Pump primed")
        self.assertEqual(
            self.scalar("SELECT last_checked FROM equipment WHERE id = 8"),
            self.scalar("SELECT date('now')"),
        )

    def test_late_check_never_moves_last_checked_back(self):
        before = self.scalar("SELECT last_checked FROM equipment WHERE id = 1")
        self.conn.execute(
            "INSERT INTO maintenance_log (equipment_id, date, action) "
            "VALUES (1, date('now', '-100 days'), 'check')"
        )
        self.assertEqual(self.scalar("SELECT last_checked FROM equipment WHERE id = 1"), before)

    def test_service_does_not_count_as_check(self):
        db.log_maintenance(self.conn, 10, "service", "Hose rolled")
        self.assertIsNone(self.scalar("SELECT last_checked FROM equipment WHERE id = 10"))


if __name__ == "__main__":
    unittest.main()