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
            password=os.getenv("DB_PASSWORD", "duyencocong2"),
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

        cursor.execute("SHOW COLUMNS FROM `groups` LIKE 'min_members'")
        result = cursor.fetchone()
        if not result:
            print("Adding min_members column to groups...")
            cursor.execute("ALTER TABLE `groups` ADD COLUMN min_members INT DEFAULT 2")
            conn.commit()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id VARCHAR(50) NOT NULL,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                type VARCHAR(50) DEFAULT 'general',
                data TEXT,
                is_read BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_notifications_user_created (user_id, created_at),
                INDEX idx_notifications_user_read (user_id, is_read)
            ) ENGINE=InnoDB
        """)
        conn.commit()

        seed_demo_course_links(cursor)
        conn.commit()

        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Lỗi khi setup database: {e}")
        if conn and conn.is_connected():
            conn.close()

def seed_demo_course_links(cursor):
    """Seed sample course links for all semester 6 students and lecturers."""
    cursor.execute("SELECT COUNT(*) FROM student_courses")
    if cursor.fetchone()[0] == 0:
        # All 10 courses for Semester 6
        s6_course_codes = [
            "0101101956", "0101101957", "0101101969", "0101101970", 
            "0101101973", "0101101974", "0101101976", "0101101977", 
            "0101101980", "0101101984"
        ]
        students = ["sv01", "sv02", "sv03", "sv04", "sv05"]
        for sv_id in students:
            for code in s6_course_codes:
                cursor.execute(
                    "INSERT IGNORE INTO student_courses (user_id, course_id) SELECT %s, id FROM courses WHERE code = %s",
                    (sv_id, code)
                )

    cursor.execute("SELECT COUNT(*) FROM lecturer_courses")
    if cursor.fetchone()[0] == 0:
        # Assign courses to gv01
        gv01_courses = ["0101101969", "0101101970", "0101101973", "0101101974", "0101101976", "0101101977", "0101101980"]
        for code in gv01_courses:
            cursor.execute(
                "INSERT IGNORE INTO lecturer_courses (user_id, course_id) SELECT %s, id FROM courses WHERE code = %s",
                ("gv01", code)
            )
        # Assign courses to gv02
        gv02_courses = ["0101101956", "0101101957", "0101101984", "0101006237", "0101101968", "0101101971", "0101101981", "0101101985", "0101101979"]
        for code in gv02_courses:
            cursor.execute(
                "INSERT IGNORE INTO lecturer_courses (user_id, course_id) SELECT %s, id FROM courses WHERE code = %s",
                ("gv02", code)
            )
