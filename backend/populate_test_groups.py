from database import get_db_connection
import mysql.connector

def populate():
    conn = get_db_connection()
    if not conn:
        print("Could not connect to database")
        return
    
    try:
        cursor = conn.cursor()
        
        # 1. Thêm sinh viên sv06 nếu chưa có
        cursor.execute("REPLACE INTO users (id, name, email, password, role, identity) VALUES (%s, %s, %s, %s, %s, %s)",
                       ('sv06', 'Trần Văn Sáu', 'sau.tv@student.edu.vn', '123456', 'student', 'MSSV2006'))
        
        # 2. Tạo Nhóm 03 (Leader: sv01, Members: sv01, sv02, sv03)
        cursor.execute("INSERT INTO `groups` (name, description, leader_id, max_members, topic_id, status) VALUES (%s, %s, %s, %s, %s, %s)",
                       ('Nhóm 03 - AI Research', 'Nghiên cứu về trí tuệ nhân tạo', 'sv01', 5, 3, 'approved'))
        group3_id = cursor.lastrowid
        
        # Thêm thành viên cho Nhóm 03
        members3 = [('sv01', 'member'), ('sv02', 'member'), ('sv03', 'member')]
        for user_id, status in members3:
            cursor.execute("REPLACE INTO group_members (group_id, user_id, status) VALUES (%s, %s, %s)", (group3_id, user_id, status))
            
        # 3. Tạo Nhóm 04 (Leader: sv04, Members: sv04, sv05, sv06)
        cursor.execute("INSERT INTO `groups` (name, description, leader_id, max_members, topic_id, status) VALUES (%s, %s, %s, %s, %s, %s)",
                       ('Nhóm 04 - Cloud Computing', 'Triển khai hạ tầng đám mây', 'sv04', 5, 1, 'pending_approval'))
        group4_id = cursor.lastrowid
        
        # Thêm thành viên cho Nhóm 04
        members4 = [('sv04', 'member'), ('sv05', 'member'), ('sv06', 'member')]
        for user_id, status in members4:
            cursor.execute("REPLACE INTO group_members (group_id, user_id, status) VALUES (%s, %s, %s)", (group4_id, user_id, status))
            
        conn.commit()
        print(f"Successfully added 2 groups (ID: {group3_id}, {group4_id}) with 3 members each.")
        
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    populate()
