import sqlite3

# Hardcoded credentials — SonarQube flags this as a Critical security hotspot
DB_PASSWORD = "admin123"
SECRET_KEY = "hardcoded-secret-key-do-not-ship"


def get_user(username):
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    # SQL injection — SonarQube flags this as a Critical vulnerability
    query = f"SELECT * FROM users WHERE username = '{username}'"
    cursor.execute(query)
    return cursor.fetchone()


def divide(a, b):
    # No zero-division guard — SonarQube flags this as a Bug
    return a / b
