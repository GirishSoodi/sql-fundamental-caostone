"""FireStation command line.

Commands:
  build                       create firestation.db with the sample data
  report                      list the report names
  report NAME [DATE]          run one report from sql/reports.sql
  set-status ID STATUS        change an item's status (fires the trigger)
  log ID ACTION NOTES         record maintenance done today
  archive                     move responses older than two years
  perf                        run the checks in sql/performance.sql
  backup                      write backups/firestation_backup.sql
  restore                     rebuild firestation_restored.db from the backup
"""
import sqlite3
import sys
from contextlib import closing
from pathlib import Path

import db

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "firestation.db"
BACKUP_PATH = ROOT / "backups" / "firestation_backup.sql"
RESTORED_PATH = ROOT / "firestation_restored.db"


# Every command opens its connection with closing(...), so the connection
# is closed even when a command stops with an error.
def open_existing():
    if not DB_PATH.exists():
        raise SystemExit("firestation.db not found. Run the build command first.")
    return db.connect(DB_PATH)


def remove_old(path):
    # On Windows a file DBeaver still has open cannot be deleted.
    try:
        if path.exists():
            path.unlink()
    except PermissionError:
        raise SystemExit("%s is in use. Disconnect it in DBeaver, then try again." % path.name)


def cmd_build(args):
    remove_old(DB_PATH)
    with closing(db.connect(DB_PATH)) as conn:
        db.build_database(conn)
        print("Built firestation.db")
        for table in ("equipment", "crew_members", "responses", "maintenance_log"):
            print("  %-16s %d rows" % (table, db.count_rows(conn, table)))


def cmd_report(args):
    queries = db.load_named_queries("reports.sql")
    if not args:
        print("Reports: " + ", ".join(queries))
        return
    name = args[0]
    if name not in queries:
        raise SystemExit("Unknown report '%s'. Reports: %s" % (name, ", ".join(queries)))
    params = {}
    if ":on_date" in queries[name]:
        if len(args) < 2:
            raise SystemExit("Report '%s' needs a date, for example 2026-08-14" % name)
        params["on_date"] = args[1]
    with closing(open_existing()) as conn:
        print("== %s ==" % name)
        print(db.format_table(*db.run_query(conn, queries[name], params)))


def cmd_set_status(args):
    if len(args) != 2:
        raise SystemExit("Usage: set-status ID STATUS")
    with closing(open_existing()) as conn:
        db.set_status(conn, int(args[0]), args[1])
        print("Equipment %s is now %s" % (args[0], args[1]))


def cmd_log(args):
    if len(args) != 3:
        raise SystemExit("Usage: log ID ACTION NOTES")
    with closing(open_existing()) as conn:
        db.log_maintenance(conn, int(args[0]), args[1], args[2])
        print("Logged %s for equipment %s" % (args[1], args[0]))


def cmd_archive(args):
    with closing(open_existing()) as conn:
        moved = db.archive_old_responses(conn)
        print("Archived %d responses older than two years" % moved)
        print("  responses          %d rows" % db.count_rows(conn, "responses"))
        print("  responses_archive  %d rows" % db.count_rows(conn, "responses_archive"))


def cmd_perf(args):
    with closing(open_existing()) as conn:
        for name, sql in db.load_named_queries("performance.sql").items():
            print("== %s ==" % name)
            headers, rows = db.run_query(conn, sql)
            if headers:
                print(db.format_table(headers, rows))
            else:
                print("done")
        conn.commit()


def cmd_backup(args):
    with closing(open_existing()) as conn:
        BACKUP_PATH.parent.mkdir(exist_ok=True)
        BACKUP_PATH.write_text(db.dump_tables(conn), encoding="utf-8")
    print("Wrote backups/firestation_backup.sql (%d tables)" % len(db.BACKUP_TABLES))


def cmd_restore(args):
    if not BACKUP_PATH.exists():
        raise SystemExit("No backup found. Run the backup command first.")
    remove_old(RESTORED_PATH)
    with closing(db.connect(RESTORED_PATH)) as conn:
        db.restore_database(conn, BACKUP_PATH.read_text(encoding="utf-8"))
        print("Restored into firestation_restored.db")
        for table in db.BACKUP_TABLES[:3]:
            print("  %-16s %d rows" % (table, db.count_rows(conn, table)))


COMMANDS = {
    "build": cmd_build,
    "report": cmd_report,
    "set-status": cmd_set_status,
    "log": cmd_log,
    "archive": cmd_archive,
    "perf": cmd_perf,
    "backup": cmd_backup,
    "restore": cmd_restore,
}


def main(argv):
    if not argv or argv[0] not in COMMANDS:
        print(__doc__)
        return 1
    try:
        COMMANDS[argv[0]](argv[1:])
    except sqlite3.Error as err:
        print("Database error: %s" % err)
        return 1
    except ValueError as err:
        print("Error: %s" % err)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))