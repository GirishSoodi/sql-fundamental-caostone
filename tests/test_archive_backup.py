import unittest

import db


class ArchiveTest(unittest.TestCase):
    def setUp(self):
        self.conn = db.connect(":memory:")
        db.build_database(self.conn)

    def tearDown(self):
        self.conn.close()

    def add_response(self, response_id, date_sql):
        self.conn.execute(
            "INSERT INTO responses (id, date, address, type) "
            "VALUES (?, date('now', ?), 'Test Street', 'fire')",
            (response_id, date_sql),
        )
        self.conn.execute(
            "INSERT INTO response_equipment (response_id, equipment_id) VALUES (?, 1)",
            (response_id,),
        )
        self.conn.execute(
            "INSERT INTO response_crew (response_id, member_id) VALUES (?, 1)",
            (response_id,),
        )
        self.conn.commit()

    def ids(self, sql):
        return {row[0] for row in self.conn.execute(sql)}

    def test_only_responses_older_than_two_years_move(self):
        self.add_response(100, "-3 years")
        self.add_response(101, "-1 years")
        self.add_response(102, "-23 months")
        db.archive_old_responses(self.conn)
        live = self.ids("SELECT id FROM responses")
        archived = self.ids("SELECT id FROM responses_archive")
        self.assertIn(100, archived)
        self.assertNotIn(100, live)
        self.assertTrue({101, 102} <= live)
        self.assertFalse({101, 102} & archived)

    def test_sample_data_is_split_at_the_cutoff(self):
        moved = db.archive_old_responses(self.conn)
        cutoff = self.conn.execute("SELECT date('now', '-2 years')").fetchone()[0]
        self.assertGreaterEqual(moved, 3)
        self.assertEqual(
            db.count_rows(self.conn, "responses") + db.count_rows(self.conn, "responses_archive"),
            13,
        )
        oldest_live = self.conn.execute("SELECT MIN(date) FROM responses").fetchone()[0]
        newest_archived = self.conn.execute(
            "SELECT MAX(date) FROM responses_archive"
        ).fetchone()[0]
        self.assertTrue(oldest_live is None or oldest_live >= cutoff)
        self.assertLess(newest_archived, cutoff)

    def test_child_rows_move_with_their_response(self):
        self.add_response(100, "-3 years")
        db.archive_old_responses(self.conn)
        self.assertEqual(
            self.ids("SELECT response_id FROM response_equipment WHERE response_id = 100"), set()
        )
        self.assertEqual(
            self.ids("SELECT response_id FROM response_equipment_archive WHERE response_id = 100"),
            {100},
        )
        self.assertEqual(
            self.ids("SELECT response_id FROM response_crew_archive WHERE response_id = 100"),
            {100},
        )
        orphans = self.conn.execute("PRAGMA foreign_key_check").fetchall()
        self.assertEqual(orphans, [])

    def test_running_archive_twice_moves_nothing_more(self):
        first = db.archive_old_responses(self.conn)
        second = db.archive_old_responses(self.conn)
        self.assertGreater(first, 0)
        self.assertEqual(second, 0)
        self.assertEqual(db.count_rows(self.conn, "responses_archive"), first)


class BackupTest(unittest.TestCase):
    def setUp(self):
        self.conn = db.connect(":memory:")
        db.build_database(self.conn)
        db.set_status(self.conn, 2, "under_repair")
        self.conn.execute(
            "INSERT INTO maintenance_log (equipment_id, date, action, notes) "
            "VALUES (2, '2026-10-01', 'repair', 'Rung bent at O''Brien''s barn')"
        )
        self.conn.commit()
        db.archive_old_responses(self.conn)

    def tearDown(self):
        self.conn.close()

    def all_rows(self, conn, table):
        return conn.execute("SELECT * FROM %s ORDER BY rowid" % table).fetchall()

    def test_dump_contains_create_insert_and_index_statements(self):
        dump = db.dump_tables(self.conn)
        self.assertTrue(dump.startswith("BEGIN TRANSACTION;"))
        self.assertTrue(dump.rstrip().endswith("COMMIT;"))
        self.assertIn("CREATE TABLE equipment", dump)
        self.assertIn("INSERT INTO equipment (id, name, type, status, last_checked)", dump)
        self.assertIn("CREATE INDEX idx_responses_date", dump)
        self.assertIn("'Rung bent at O''Brien''s barn'", dump)
        self.assertIn("NULL);", dump)

    def test_restore_gives_back_identical_rows(self):
        restored = db.connect(":memory:")
        db.restore_database(restored, db.dump_tables(self.conn))
        for table in db.BACKUP_TABLES:
            self.assertEqual(
                self.all_rows(restored, table), self.all_rows(self.conn, table), table
            )
        restored.close()

    def test_restored_database_has_working_trigger_and_view(self):
        restored = db.connect(":memory:")
        db.restore_database(restored, db.dump_tables(self.conn))
        db.set_status(restored, 2, "in_service")
        self.assertEqual(db.count_rows(restored, "status_change_log"), 2)
        ready = restored.execute(
            "SELECT readiness FROM readiness_view WHERE name = 'Ladder 1'"
        ).fetchone()[0]
        self.assertEqual(ready, "ready")
        restored.close()


if __name__ == "__main__":
    unittest.main()

