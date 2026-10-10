import unittest

import db


class ReportsTest(unittest.TestCase):
    def setUp(self):
        self.conn = db.connect(":memory:")
        db.build_database(self.conn)
        self.reports = db.load_named_queries("reports.sql")

    def tearDown(self):
        self.conn.close()

    def report(self, name, **params):
        return db.run_query(self.conn, self.reports[name], params)

    def test_every_report_is_found_in_the_file(self):
        self.assertEqual(
            list(self.reports),
            [
                "monthly_summary",
                "equipment_usage",
                "not_ready",
                "equipment_on_date",
                "crew_on_date",
                "responses_by_type",
                "not_checked_30_days",
                "status_history",
            ],
        )

    def test_readiness_view_lists_not_ready_items_with_reason(self):
        headers, rows = self.report("not_ready")
        reasons = {row[0]: row[4] for row in rows}
        self.assertEqual(
            reasons,
            {
                "Hose Bundle 3": "never checked",
                "Portable Pump": "check overdue",
                "Rescue 1": "under_repair",
                "SCBA Pack B": "out_of_service",
                "Thermal Camera": "check overdue",
            },
        )

    def test_readiness_view_shows_latest_maintenance_date(self):
        latest, expected = self.conn.execute(
            "SELECT latest_maintenance, date('now', '-45 days') "
            "FROM readiness_view WHERE name = 'Thermal Camera'"
        ).fetchone()
        self.assertEqual(latest, expected)
        never = self.conn.execute(
            "SELECT latest_maintenance FROM readiness_view WHERE name = 'Hose Bundle 3'"
        ).fetchone()[0]
        self.assertIsNone(never)

    def test_readiness_view_follows_status_changes(self):
        db.set_status(self.conn, 1, "out_of_service")
        _, rows = self.report("not_ready")
        self.assertIn("Engine 1 Pumper", [row[0] for row in rows])
        db.log_maintenance(self.conn, 6, "check", "Camera tested")
        _, rows = self.report("not_ready")
        self.assertNotIn("Thermal Camera", [row[0] for row in rows])

    def test_monthly_summary(self):
        headers, rows = self.report("monthly_summary")
        self.assertEqual(headers, ["month", "total", "fire", "medical", "rescue", "other"])
        self.assertEqual(
            rows,
            [
                ("2022-11", 1, 1, 0, 0, 0),
                ("2023-02", 1, 0, 0, 1, 0),
                ("2023-06", 1, 0, 1, 0, 0),
                ("2026-07", 3, 1, 1, 0, 1),
                ("2026-08", 4, 1, 1, 1, 1),
                ("2026-09", 3, 1, 1, 0, 1),
            ],
        )

    def test_equipment_usage_counts_include_unused_items(self):
        _, rows = self.report("equipment_usage")
        usage = {row[0]: row[2] for row in rows}
        self.assertEqual(len(usage), 11)
        self.assertEqual(usage["Engine 1 Pumper"], 7)
        self.assertEqual(usage["Hose Bundle 3"], 0)
        self.assertEqual(rows[0][0], "Engine 1 Pumper")

    def test_equipment_used_on_a_date(self):
        _, rows = self.report("equipment_on_date", on_date="2026-08-14")
        self.assertEqual(
            [(row[1], row[3]) for row in rows],
            [
                ("101 Market Square", "Engine 1 Pumper"),
                ("101 Market Square", "Ladder 1"),
                ("101 Market Square", "SCBA Pack A"),
                ("101 Market Square", "SCBA Pack B"),
                ("101 Market Square", "Thermal Camera"),
                ("45 Birch Avenue", "Defibrillator"),
            ],
        )

    def test_date_with_no_calls_returns_nothing(self):
        _, rows = self.report("equipment_on_date", on_date="2026-01-01")
        self.assertEqual(rows, [])

    def test_crew_on_a_date(self):
        _, rows = self.report("crew_on_date", on_date="2026-07-19")
        self.assertEqual(
            [(row[1], row[2]) for row in rows],
            [
                ("22 Elm Road", "Lee Wong"),
                ("3 Station Hill", "Sam Okafor"),
                ("3 Station Hill", "Tom Becker"),
            ],
        )

    def test_responses_grouped_by_type(self):
        _, rows = self.report("responses_by_type")
        self.assertEqual(
            rows,
            [("fire", 4), ("medical", 4), ("alarm", 2), ("rescue", 2), ("hazmat", 1)],
        )

    def test_not_checked_in_30_days_includes_never_checked(self):
        _, rows = self.report("not_checked_30_days")
        self.assertEqual(
            [(row[0], row[3]) for row in rows],
            [("Hose Bundle 3", None), ("Portable Pump", 60), ("Thermal Camera", 45)],
        )

    def test_status_history_report(self):
        db.set_status(self.conn, 5, "in_service")
        _, rows = self.report("status_history")
        self.assertEqual(rows[0][1:4], ("SCBA Pack B", "out_of_service", "in_service"))

    def test_indexes_are_used_by_the_planner(self):
        perf = db.load_named_queries("performance.sql")
        db.run_query(self.conn, perf["analyze"])
        _, plan = db.run_query(self.conn, perf["plan_responses_by_date"])
        self.assertIn("idx_responses_date", plan[0][3])
        _, plan = db.run_query(self.conn, perf["plan_equipment_by_status"])
        self.assertIn("idx_equipment_status", plan[0][3])
        _, rows = db.run_query(self.conn, perf["integrity_check"])
        self.assertEqual(rows, [("ok",)])

    def test_format_table_pads_columns(self):
        text = db.format_table(["a", "name"], [(1, "Ladder 1"), (22, None)])
        self.assertEqual(
            text.splitlines(),
            ["a   name", "--  --------", "1   Ladder 1", "22", "(2 rows)"],
        )


if __name__ == "__main__":
    unittest.main()