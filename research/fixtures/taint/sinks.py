"""Fixture file exercising SQL/web/shell sinks for tldr taint analysis."""

import os
import sqlite3
import subprocess


def vulnerable_sql(user_id):
    """SQL injection: user input concatenated into query."""
    conn = sqlite3.connect("db.sqlite")
    cursor = conn.cursor()
    query = "SELECT * FROM users WHERE id = " + user_id
    cursor.execute(query)
    return cursor.fetchall()


def safe_sql(user_id):
    """Parameterized query — safe."""
    conn = sqlite3.connect("db.sqlite")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    return cursor.fetchall()


def vulnerable_shell(filename):
    """Command injection: user input passed to shell."""
    cmd = "cat " + filename
    return subprocess.run(cmd, shell=True, capture_output=True)


def vulnerable_eval(user_expr):
    """Code injection via eval."""
    return eval(user_expr)


def safe_function(value):
    """No external input, no sinks."""
    result = value * 2
    return result


def vulnerable_path(user_path):
    """Path traversal via os.path.join with user input."""
    full = os.path.join("/var/data", user_path)
    with open(full) as f:
        return f.read()
