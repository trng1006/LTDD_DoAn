from fastapi import FastAPI, HTTPException, Depends, Body
from typing import List, Optional
from pydantic import BaseModel
import json
from database import get_db_connection
import mysql.connector

app = FastAPI(title="Hệ thống Đăng ký Đề tài API")

# --- Models ---

class UserBase(BaseModel):
    id: str
    username: Optional[str] = None # Added username field
    name: str
    email: str
    role: str
    identity: Optional[str] = None
    password: Optional[str] = None
    enrolledCourseIds: Optional[List[str]] = []
    taughtCourseIds: Optional[List[str]] = []
    currentSemesterId: Optional[str] = None

class TopicBase(BaseModel):
    id: Optional[str] = None
    title: str
    description: Optional[str] = ""
    lecturerId: str
    courseId: str
    maxGroups: int = 1
    currentGroups: int = 0
    startTime: Optional[str] = None
    endTime: Optional[str] = None

class GroupBase(BaseModel):
    id: Optional[str] = None
    name: str
    description: Optional[str] = ""
    leaderId: str
    courseId: str
    maxMembers: int = 5
    minMembers: int = 2
    topicId: Optional[str] = None
    status: str = "creating"
    isLocked: bool = False

class RegisterTopicRequest(BaseModel):
    topicId: str
    leaderId: str

class LoginRequest(BaseModel):
    identity: str
    password: str

# --- Helper Mappings ---

def map_user(row, course_ids=None):
    user_data = {
        "id": row["id"],
        "username": row.get("username") or row["id"],
        "name": row["name"],
        "email": row["email"],
        "role": row["role"],
        "identity": row["identity"],
        "currentSemesterId": row["current_semester_id"]
    }
    
    if row["role"] == 'student':
        user_data["enrolledCourseIds"] = course_ids if course_ids is not None else []
    elif row["role"] == 'lecturer':
        user_data["taughtCourseIds"] = course_ids if course_ids is not None else []
        
    return user_data

def map_topic(row):
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "description": row["description"] or "",
        "lecturerId": row["lecturer_id"],
        "courseId": row["course_id"],
        "maxGroups": row["max_groups"],
        "currentGroups": row["current_groups"],
        "startTime": row["start_time"].isoformat() if row["start_time"] else None,
        "endTime": row["end_time"].isoformat() if row["end_time"] else None
    }

def map_group(row):
    return {
        "id": str(row["id"]),
        "name": row["name"],
        "description": row["description"] or "",
        "leaderId": row["leader_id"],
        "courseId": row["course_id"],
        "maxMembers": row["max_members"],
        "minMembers": row.get("min_members", 2),
        "topicId": str(row["topic_id"]) if row["topic_id"] else None,
        "status": row["status"],
        "isLocked": bool(row["is_locked"])
    }

# --- Routes ---

@app.get("/")
def read_root():
    return {"message": "Welcome to Student Registration API"}

@app.post("/login")
def login(req: LoginRequest):
    print(f"DEBUG: Login attempt with identity: {req.identity}")
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor(dictionary=True)
        query = "SELECT id, username, name, email, role, identity, current_semester_id FROM users WHERE (id = %s OR email = %s OR identity = %s OR username = %s) AND password = %s"
        cursor.execute(query, (req.identity, req.identity, req.identity, req.identity, req.password))
        user = cursor.fetchone()
        
        if user:
            course_ids = []
            if user['role'] == 'student':
                cursor.execute("SELECT course_id FROM student_courses WHERE user_id = %s", (user['id'],))
            elif user['role'] == 'lecturer':
                cursor.execute("SELECT course_id FROM lecturer_courses WHERE user_id = %s", (user['id'],))
            
            if user['role'] in ['student', 'lecturer']:
                course_ids = [c['course_id'] for c in cursor.fetchall()]
            
            cursor.close()
            conn.close()
            print(f"DEBUG: Login successful for user: {user['name']}")
            return map_user(user, course_ids)
            
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        print(f"DEBUG: Login Error: {str(e)}")
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users")
def get_users(role: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if role:
        cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id FROM users WHERE role = %s", (role,))
    else:
        cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id FROM users")
    users = cursor.fetchall()
    
    mapped_users = []
    for u in users:
        course_ids = []
        if u['role'] == 'student':
            cursor.execute("SELECT course_id FROM student_courses WHERE user_id = %s", (u['id'],))
            course_ids = [c['course_id'] for c in cursor.fetchall()]
        elif u['role'] == 'lecturer':
            cursor.execute("SELECT course_id FROM lecturer_courses WHERE user_id = %s", (u['id'],))
            course_ids = [c['course_id'] for c in cursor.fetchall()]
        mapped_users.append(map_user(u, course_ids))
        
    cursor.close()
    conn.close()
    return mapped_users

@app.post("/users", response_model=UserBase)
def create_user(user: UserBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        conn.start_transaction()
        # 1. Thêm user vào bảng users
        query = "INSERT INTO users (id, username, name, email, password, role, identity, current_semester_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (user.id, user.username or user.id, user.name, user.email, user.password or '123', user.role, user.identity, user.currentSemesterId))

        
        if user.role == 'student' and user.enrolledCourseIds:
            for c_id in user.enrolledCourseIds:
                cursor.execute("INSERT INTO student_courses (user_id, course_id) VALUES (%s, %s)", (user.id, c_id))
        elif user.role == 'lecturer' and user.taughtCourseIds:
            for c_id in user.taughtCourseIds:
                cursor.execute("INSERT INTO lecturer_courses (user_id, course_id) VALUES (%s, %s)", (user.id, c_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        return user
    except mysql.connector.Error as err:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        # Xử lý lỗi trùng lặp (Duplicate Entry)
        if err.errno == 1062:
            msg = str(err.msg)
            if "username" in msg:
                raise HTTPException(status_code=400, detail="Tên đăng nhập đã tồn tại. Vui lòng chọn tên khác.")
            if "email" in msg:
                raise HTTPException(status_code=400, detail="Email này đã được sử dụng.")
            if "identity" in msg:
                raise HTTPException(status_code=400, detail="Mã số (MSSV/MSGV) đã tồn tại.")
        raise HTTPException(status_code=400, detail=str(err))

@app.put("/users/{user_id}", response_model=UserBase)
def update_user(user_id: str, user: UserBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        conn.start_transaction()
        # 1. Cập nhật thông tin cơ bản
        query = "UPDATE users SET username=%s, name=%s, email=%s, role=%s, identity=%s, current_semester_id=%s WHERE id=%s"
        cursor.execute(query, (user.username or user.id, user.name, user.email, user.role, user.identity, user.currentSemesterId, user_id))

        
        if user.role == 'student':
            cursor.execute("DELETE FROM student_courses WHERE user_id = %s", (user_id,))
            if user.enrolledCourseIds:
                for c_id in user.enrolledCourseIds:
                    cursor.execute("INSERT INTO student_courses (user_id, course_id) VALUES (%s, %s)", (user_id, c_id))
        elif user.role == 'lecturer':
            cursor.execute("DELETE FROM lecturer_courses WHERE user_id = %s", (user_id,))
            if user.taughtCourseIds:
                for c_id in user.taughtCourseIds:
                    cursor.execute("INSERT INTO lecturer_courses (user_id, course_id) VALUES (%s, %s)", (user_id, c_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        return user
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        # Xử lý lỗi trùng lặp (Duplicate Entry) cho MySQL Connector
        if hasattr(e, 'errno') and e.errno == 1062:
            msg = str(e.msg) if hasattr(e, 'msg') else str(e)
            if "username" in msg:
                raise HTTPException(status_code=400, detail="Tên đăng nhập đã tồn tại. Vui lòng chọn tên khác.")
            if "email" in msg:
                raise HTTPException(status_code=400, detail="Email này đã được sử dụng.")
            if "identity" in msg:
                raise HTTPException(status_code=400, detail="Mã số (MSSV/MSGV) đã tồn tại.")
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/users/{user_id}")
def delete_user(user_id: str):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "User deleted"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/semesters")
def get_semesters():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM semesters")
    rows = cursor.fetchall()
    semesters = []
    for r in rows:
        semesters.append({
            "id": r["id"],
            "name": r["name"],
            "isActive": bool(r["is_active"])
        })
    cursor.close()
    conn.close()
    return semesters

# --- Topic Routes ---

@app.get("/topics")
def get_topics():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM topics")
    rows = cursor.fetchall()
    topics = [map_topic(r) for r in rows]
    cursor.close()
    conn.close()
    return topics

@app.post("/topics")
def create_topic(topic: TopicBase):
    print(f"DEBUG: Request to create topic: {topic.dict()}")
    conn = get_db_connection()
    if not conn:
        print("DEBUG: Database connection failed")
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor()
        query = "INSERT INTO topics (title, description, lecturer_id, course_id, max_groups) VALUES (%s, %s, %s, %s, %s)"
        print(f"DEBUG: Executing query: {query} with values: {(topic.title, topic.description, topic.lecturerId, topic.courseId, topic.maxGroups)}")
        cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.courseId, topic.maxGroups))
        conn.commit()
        topic_id = cursor.lastrowid
        print(f"DEBUG: Topic created successfully with ID: {topic_id}")
        cursor.close()
        conn.close()
        return {"id": str(topic_id), "message": "Topic created"}
    except Exception as e:
        print(f"DEBUG: Error in create_topic: {str(e)}")
        if conn and conn.is_connected(): 
            conn.rollback()
            conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/topics/{topic_id}")
def update_topic(topic_id: int, topic: TopicBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "UPDATE topics SET title=%s, description=%s, lecturer_id=%s, course_id=%s, max_groups=%s WHERE id=%s"
        cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.courseId, topic.maxGroups, topic_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic updated"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/topics/{topic_id}")
def delete_topic(topic_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM topics WHERE id = %s", (topic_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Topic deleted"}

# --- Group Routes ---

@app.get("/groups")
def get_groups(topic_id: Optional[int] = None, course_id: Optional[str] = None, search: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    # Hỗ trợ tìm kiếm nhóm theo môn học và/hoặc từ khoá tên nhóm (cho chức năng Tham gia nhóm)
    conditions = []
    params = []
    if topic_id:
        conditions.append("topic_id = %s")
        params.append(topic_id)
    if course_id:
        conditions.append("course_id = %s")
        params.append(course_id)
    if search:
        conditions.append("name LIKE %s")
        params.append(f"%{search}%")

    sql = "SELECT * FROM `groups`"
    if conditions:
        sql += " WHERE " + " AND ".join(conditions)
    cursor.execute(sql, tuple(params))
    rows = cursor.fetchall()
    groups = []
    for row in rows:
        g = map_group(row)
        cursor.execute("""
            SELECT u.id, u.name, u.identity, gm.status 
            FROM group_members gm 
            JOIN users u ON gm.user_id = u.id 
            WHERE gm.group_id = %s
        """, (row['id'],))
        members = cursor.fetchall()
        g['memberIds'] = [m['id'] for m in members if m['status'] == 'member']
        g['pendingMemberIds'] = [m['id'] for m in members if m['status'] == 'pending']
        groups.append(g)
    cursor.close()
    conn.close()
    return groups

@app.post("/groups")
def create_group(group: GroupBase):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor(dictionary=True)
        # RÀNG BUỘC: Mỗi sinh viên chỉ được thuộc 1 nhóm trong cùng một môn học.
        # Kiểm tra xem trưởng nhóm đã là thành viên (member/pending) của nhóm nào khác cùng môn chưa.
        cursor.execute("""
            SELECT g.id FROM `groups` g
            JOIN group_members gm ON gm.group_id = g.id
            WHERE gm.user_id = %s AND g.course_id = %s
        """, (group.leaderId, group.courseId))
        existing = cursor.fetchone()
        if existing:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Bạn đã ở trong một nhóm khác của môn học này. Mỗi sinh viên chỉ được tham gia 1 nhóm.")

        # Validation số lượng thành viên min/max hợp lệ
        if group.minMembers < 1 or group.maxMembers < group.minMembers:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Số thành viên tối thiểu/tối đa không hợp lệ.")

        cursor2 = conn.cursor()
        query = "INSERT INTO `groups` (name, description, leader_id, course_id, max_members, min_members, topic_id) VALUES (%s, %s, %s, %s, %s, %s, %s)"
        cursor2.execute(query, (group.name, group.description, group.leaderId, group.courseId, group.maxMembers, group.minMembers, group.topicId))
        group_id = cursor2.lastrowid
        cursor2.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, group.leaderId))
        conn.commit()
        cursor.close()
        cursor2.close()
        conn.close()
        return {"id": str(group_id), "message": "Group created successfully"}
    except HTTPException:
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        # Xử lý lỗi trùng lặp (Duplicate Entry) cho MySQL Connector
        if hasattr(e, 'errno') and e.errno == 1062:
            msg = str(e.msg) if hasattr(e, 'msg') else str(e)
            if "username" in msg:
                raise HTTPException(status_code=400, detail="Tên đăng nhập đã tồn tại. Vui lòng chọn tên khác.")
            if "email" in msg:
                raise HTTPException(status_code=400, detail="Email này đã được sử dụng.")
            if "identity" in msg:
                raise HTTPException(status_code=400, detail="Mã số (MSSV/MSGV) đã tồn tại.")
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/groups/{group_id}")
def update_group(group_id: int, group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "UPDATE `groups` SET name=%s, description=%s, leader_id=%s, course_id=%s, max_members=%s, min_members=%s, topic_id=%s, status=%s, is_locked=%s WHERE id=%s"
        cursor.execute(query, (group.name, group.description, group.leaderId, group.courseId, group.maxMembers, group.minMembers, group.topicId, group.status, group.isLocked, group_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Group updated"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/join")
def join_group(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT is_locked, max_members, course_id, (SELECT COUNT(*) FROM group_members WHERE group_id=%s AND status='member') as current_members FROM `groups` WHERE id=%s", (group_id, group_id))
        group_info = cursor.fetchone()
        if not group_info: raise HTTPException(status_code=404, detail="Group not found")
        if group_info[0]: raise HTTPException(status_code=400, detail="Nhóm đã bị khoá, không thể tham gia.")
        if group_info[3] >= group_info[1]: raise HTTPException(status_code=400, detail="Nhóm đã đủ số lượng thành viên tối đa.")

        # RÀNG BUỘC: Mỗi sinh viên chỉ được thuộc 1 nhóm trong cùng một môn học.
        course_id = group_info[2]
        cursor.execute("""
            SELECT g.id FROM `groups` g
            JOIN group_members gm ON gm.group_id = g.id
            WHERE gm.user_id = %s AND g.course_id = %s
        """, (user_id, course_id))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Bạn đã ở trong một nhóm khác của môn học này. Mỗi sinh viên chỉ được tham gia 1 nhóm.")

        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'pending')", (group_id, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Join request sent"}
    except HTTPException:
        if conn and conn.is_connected(): conn.close()
        raise
    except mysql.connector.Error:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail="Bạn đã gửi yêu cầu hoặc đã ở trong nhóm này.")

@app.post("/groups/{group_id}/approve-member")
def approve_member(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE group_members SET status='member' WHERE group_id=%s AND user_id=%s", (group_id, user_id))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Member approved"}

@app.delete("/groups/{group_id}/members/{user_id}")
def remove_member(group_id: int, user_id: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Member removed"}

@app.get("/topics/available")
def get_available_topics(course_id: Optional[str] = None):
    """Danh sách đề tài còn chỗ (current_groups < max_groups) để trưởng nhóm chọn đăng ký."""
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    cursor = conn.cursor(dictionary=True)
    if course_id:
        cursor.execute("SELECT * FROM topics WHERE current_groups < max_groups AND course_id = %s", (course_id,))
    else:
        cursor.execute("SELECT * FROM topics WHERE current_groups < max_groups")
    rows = cursor.fetchall()
    topics = [map_topic(r) for r in rows]
    cursor.close()
    conn.close()
    return topics

@app.post("/groups/{group_id}/register-topic")
def register_topic(group_id: int, req: RegisterTopicRequest):
    """Trưởng nhóm đăng ký đề tài cho nhóm.
    Validation: chỉ trưởng nhóm được đăng ký, kiểm tra số thành viên tối thiểu/tối đa,
    đề tài còn chỗ, rồi chuyển nhóm sang trạng thái 'approved' và khoá nhóm.
    """
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor(dictionary=True)
        # Lấy thông tin nhóm
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm.")

        # Chỉ trưởng nhóm mới được đăng ký đề tài
        if group["leader_id"] != req.leaderId:
            raise HTTPException(status_code=403, detail="Chỉ trưởng nhóm mới được đăng ký đề tài.")

        if group["is_locked"] or group["status"] == "approved":
            raise HTTPException(status_code=400, detail="Nhóm đã chốt đề tài trước đó.")

        # Đếm số thành viên chính thức để validate min/max
        cursor.execute("SELECT COUNT(*) AS n FROM group_members WHERE group_id = %s AND status = 'member'", (group_id,))
        member_count = cursor.fetchone()["n"]

        min_members = group.get("min_members") or 2
        max_members = group["max_members"]
        if member_count < min_members:
            raise HTTPException(status_code=400, detail=f"Nhóm chưa đủ thành viên tối thiểu ({member_count}/{min_members}). Vui lòng bổ sung thành viên trước khi đăng ký.")
        if member_count > max_members:
            raise HTTPException(status_code=400, detail=f"Nhóm vượt quá số thành viên tối đa ({member_count}/{max_members}).")

        # Kiểm tra đề tài tồn tại và còn chỗ
        cursor.execute("SELECT current_groups, max_groups FROM topics WHERE id = %s", (req.topicId,))
        topic = cursor.fetchone()
        if not topic:
            raise HTTPException(status_code=404, detail="Không tìm thấy đề tài.")
        if topic["current_groups"] >= topic["max_groups"]:
            raise HTTPException(status_code=400, detail="Đề tài này đã đủ số lượng nhóm đăng ký.")

        # Cập nhật nhóm: gán đề tài, duyệt và khoá nhóm.
        # Trigger 'after_group_update_approved' sẽ tự tăng current_groups của đề tài.
        cursor2 = conn.cursor()
        cursor2.execute(
            "UPDATE `groups` SET topic_id = %s, status = 'approved', is_locked = TRUE WHERE id = %s",
            (req.topicId, group_id),
        )
        conn.commit()
        cursor.close()
        cursor2.close()
        conn.close()
        return {"message": "Đăng ký đề tài thành công.", "topicId": req.topicId}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except mysql.connector.Error as err:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        # Bắt thông báo từ các trigger SQL (SIGNAL SQLSTATE '45000')
        raise HTTPException(status_code=400, detail=str(err.msg) if hasattr(err, 'msg') else str(err))
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
