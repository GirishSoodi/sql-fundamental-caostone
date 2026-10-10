"""FireStation database helpers: build, query, archive, back up and restore.

All the real work is done by the SQL files in the sql folder. This module
only opens the database, runs those files and formats the results.
"""
import sqlite3
from pathlib import Path

SQL_DIR = Path(__file__).resolve().parent / "sql"

# Parents before children, so a restore never inserts a row whose
# foreign key points at a row that does not exist yet.
BACKUP_TABLES = [
    "equipment",
    "crew_members",
    "responses",
    "response_equipment",
    "response_crew",
    "maintenance_log",
    "status_change_log",
    "responses_archive",
    "response_equipment_archive",
    "response_crew_archive",
]


def connect(path):
    """Open a database and switch on foreign key checks for this connection."""
    conn = sqlite3.connect(str(path))
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def read_sql(filename):
    return (SQL_DIR / filename).read_text(encoding="utf-8")


def build_database(conn):
    """Create tables, indexes, triggers, the view, and load the sample data."""
    for filename in ("schema.sql", "logic.sql", "sample_data.sql"):
        conn.executescript(read_sql(filename))
    conn.commit()


def load_named_queries(filename):
    """Split a file into {name: sql} using its '-- name: xxx' marker lines."""
    queries = {}
    current = None
    for line in read_sql(filename).splitlines():
        stripped = line.strip()
        if stripped.startswith("-- name:"):
            current = stripped[len("-- name:"):].strip()
            queries[current] = []
        elif current is not None:
            queries[current].append(line)
    return {name: "\n".join(lines).strip() for name, lines in queries.items()}


def run_query(conn, sql, params=None):
    """Run one statement and return (column names, rows)."""
    cursor = conn.execute(sql, params or {})
    headers = [col[0] for col in cursor.description] if cursor.description else []
    return headers, cursor.fetchall()


def set_status(conn, equipment_id, status):
    """Change one item's status. The trigger records the change."""
    cursor = conn.execute(
        "UPDATE equipment SET status = ? WHERE id = ?", (status, equipment_id)
    )
    if cursor.rowcount == 0:
        conn.rollback()
        raise ValueError("no equipment with id %s" % equipment_id)
    conn.commit()


def log_maintenance(conn, equipment_id, action, notes):
    """Record maintenance done today. A 'check' also updates last_checked."""
    conn.execute(
        "INSERT INTO maintenance_log (equipment_id, date, action, notes) "
        "VALUES (?, date('now'), ?, ?)",
        (equipment_id, action, notes),
    )
    conn.commit()


def count_rows(conn, table):
    return conn.execute("SELECT COUNT(*) FROM %s" % table).fetchone()[0]


def archive_old_responses(conn):
    """Run the archive script and return how many responses were moved."""
    before = count_rows(conn, "responses")
    conn.executescript(read_sql("archive.sql"))
    return before - count_rows(conn, "responses")


def dump_tables(conn):
    """Return a .sql text that recreates BACKUP_TABLES with all their rows."""
    lines = ["BEGIN TRANSACTION;"]
    for table in BACKUP_TABLES:
        create_sql = conn.execute(
            "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
            (table,),
        ).fetchone()[0]
        lines.append(create_sql + ";")
        columns = [row[1] for row in conn.execute("PRAGMA table_info(%s)" % table)]
        # quote() lets SQLite write each value as a correct SQL literal:
        # text gets quotes (with ' doubled), NULL stays NULL, numbers stay bare.
        # quote() hands integers back as int, hence the str() below.
        select = "SELECT %s FROM %s ORDER BY rowid" % (
            ", ".join("quote(%s)" % c for c in columns),
            table,
        )
        for row in conn.execute(select):
            lines.append(
                "INSERT INTO %s (%s) VALUES (%s);"
                % (table, ", ".join(columns), ", ".join(str(v) for v in row))
            )
        for (index_sql,) in conn.execute(
            "SELECT sql FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = ? AND sql IS NOT NULL ORDER BY name",
            (table,),
        ):
            lines.append(index_sql + ";")
    lines.append("COMMIT;")
    return "\n".join(lines) + "\n"


def restore_database(conn, dump_text):
    """Load a dump into an empty database, then recreate triggers and view."""
    conn.executescript(dump_text)
    conn.executescript(read_sql("logic.sql"))
    conn.commit()


def format_table(headers, rows):
    """Plain-text table with columns padded to the widest value."""
    text_rows = [["" if v is None else str(v) for v in row] for row in rows]
    widths = [len(h) for h in headers]
    for row in text_rows:
        for i, value in enumerate(row):
            widths[i] = max(widths[i], len(value))

    def line(values):
        return "  ".join(v.ljust(w) for v, w in zip(values, widths)).rstrip()

    out = [line(headers), line(["-" * w for w in widths])]
    out.extend(line(row) for row in text_rows)
    out.append("(%d row%s)" % (len(rows), "" if len(rows) == 1 else "s"))
    return "\n".join(out)