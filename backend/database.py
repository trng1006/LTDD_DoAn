import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    try:
        # Lấy thông tin từ .env hoặc dùng giá trị mặc định
        # Đã thêm tham số port=3307 để khớp với cấu hình XAMPP của bạn
        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST", "127.0.0.1"),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", "student_registration"),
            port=int(os.getenv("DB_PORT", 3306))  # <-- Cấu hình cổng 3306 ở đây
        )
        if connection.is_connected():
            return connection
        else:
            print("DEBUG: Connection failed: connection.is_connected() is False")
            return None
    except Error as e:
        print(f"DEBUG: Connection details - Host: {os.getenv('DB_HOST', '127.0.0.1')}, Port: {os.getenv('DB_PORT', 3306)}, User: {os.getenv('DB_USER', 'root')}, DB: {os.getenv('DB_NAME', 'student_registration')}")
        print(f"DEBUG: Error while connecting to MySQL: {e}")
        return None
    except Exception as e:
        print(f"DEBUG: Unexpected error in get_db_connection: {e}")
        return None