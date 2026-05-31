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

def ensure_db_setup():
    """Tự động kiểm tra và cập nhật cấu trúc Database (is_active, v.v.)"""
    conn = get_db_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        # 1. Kiểm tra và thêm cột is_active vào bảng users nếu chưa có
        cursor.execute("SHOW COLUMNS FROM users LIKE 'is_active'")
        result = cursor.fetchone()
        if not result:
            print("Bổ sung cột is_active vào bảng users...")
            cursor.execute("ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE")
            conn.commit()
            
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Lỗi khi setup database: {e}")
        if conn and conn.is_connected():
            conn.close()