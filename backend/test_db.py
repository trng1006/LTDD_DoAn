import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

load_dotenv()

def check_db():
    try:
        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST", "localhost"),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
        )
        if connection.is_connected():
            cursor = connection.cursor()
            cursor.execute("SHOW DATABASES LIKE 'student_registration';")
            db = cursor.fetchone()
            if db:
                print(f"Database 'student_registration' exists.")
                cursor.execute("USE student_registration;")
                cursor.execute("SELECT id, email, password FROM users;")
                users = cursor.fetchall()
                print("Users in database:")
                for u in users:
                    print(u)
            else:
                print("Database 'student_registration' DOES NOT exist.")
            cursor.close()
            connection.close()
    except Error as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_db()
