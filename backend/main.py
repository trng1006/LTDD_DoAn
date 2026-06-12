#-----------------
from fastapi import FastAPI, HTTPException, Body
from typing import List, Optional
from pydantic import BaseModel
from database import get_db_connection, ensure_db_setup
import mysql.connector
from fastapi.middleware.cors import CORSMiddleware
import json
import os

app = FastAPI(title="Hệ thống Đăng ký Đề tài API")

@app.on_event("startup")
def startup_event():
    ensure_db_setup()

#python3 -m uvicorn main:app --reload
# --- CORS configuration ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Models ---

class UserBase(BaseModel):
    id: str
    username: Optional[str] = None
    name: str
    email: str
    role: str
    identity: Optional[str] = None
    password: Optional[str] = None
    enrolledCourseIds: Optional[List[str]] = []
    taughtCourseIds: Optional[List[str]] = []
    currentSemesterId: Optional[str] = None
    isActive: Optional[bool] = True # Mới: Trạng thái hoạt động của người dùng

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

class SystemSettingsUpdate(BaseModel):
    registration_start: str
    registration_end: str
    min_members: int
    max_members: int

class SemesterBase(BaseModel):
    id: str
    name: str
    isActive: bool = False

class CourseBase(BaseModel):
    id: str
    name: str
    code: str
    semesterId: Optional[str] = None

class NotificationBase(BaseModel):
    id: Optional[str] = None
    title: str
    message: str
    userId: str
    type: Optional[str] = "general"
    data: Optional[dict] = None
    isRead: Optional[bool] = False

# --- Helper Mappings ---
def map_user(row, course_ids=None):
    user_data = {
        "id": row["id"],
        "username": row.get("username") or row["id"],
        "name": row["name"],
        "email": row["email"],
        "role": row["role"],
        "identity": row["identity"],
        "currentSemesterId": row["current_semester_id"],
        "isActive": bool(row.get("is_active", 1)) # Mới: Trạng thái hoạt động của người dùng, mặc định là True nếu không có trường này trong DB
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

def map_group(row, member_ids=None, pending_member_ids=None):
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
        "isLocked": bool(row["is_locked"]),
        "memberIds": member_ids if member_ids is not None else [],
        "pendingMemberIds": pending_member_ids if pending_member_ids is not None else []
    }

def map_notification(row):
    data = {}
    if row.get("data"):
        try:
            data = json.loads(row["data"])
        except Exception:
            data = {}
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "message": row["message"],
        "timestamp": row["created_at"].isoformat() if row["created_at"] else None,
        "userId": row["user_id"],
        "type": row.get("type") or "general",
        "data": data,
        "isRead": bool(row.get("is_read", 0))
    }

def create_notification(cursor, user_id: Optional[str], title: str, message: str, notif_type: str = "general", data: Optional[dict] = None):
    if not user_id:
        return
    cursor.execute(
        "INSERT INTO notifications (user_id, title, message, type, data) VALUES (%s, %s, %s, %s, %s)",
        (user_id, title, message, notif_type, json.dumps(data or {}, ensure_ascii=False))
    )

def get_group_members(cursor, group_id: int):
    cursor.execute("SELECT user_id, status FROM group_members WHERE group_id = %s", (group_id,))
    rows = cursor.fetchall()
    member_ids = [r["user_id"] for r in rows if r["status"] == "member"]
    pending_member_ids = [r["user_id"] for r in rows if r["status"] == "pending"]
    return member_ids, pending_member_ids

def notify_group_members(cursor, group_id: int, title: str, message: str, notif_type: str, data: Optional[dict] = None):
    cursor.execute("SELECT user_id FROM group_members WHERE group_id = %s AND status = 'member'", (group_id,))
    for row in cursor.fetchall():
        create_notification(cursor, row["user_id"], title, message, notif_type, data)

def ensure_lecturer_teaches_course(cursor, lecturer_id: str, course_id: str):
    cursor.execute("SELECT role FROM users WHERE id = %s", (lecturer_id,))
    user = cursor.fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="Không tìm thấy giảng viên.")
    if user["role"] != "lecturer":
        raise HTTPException(status_code=400, detail="Người phụ trách đề tài phải là giảng viên.")

    cursor.execute(
        "SELECT 1 FROM lecturer_courses WHERE user_id = %s AND course_id = %s",
        (lecturer_id, course_id),
    )
    if not cursor.fetchone():
        raise HTTPException(
            status_code=403,
            detail="Giảng viên này chưa được phân công dạy môn học đã chọn.",
        )

# --- Routes ---

@app.get("/")
def read_root():
    return {"message": "Welcome to Student Registration API"}

@app.post("/login")
def login(req: LoginRequest):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor(dictionary=True)
        #Thêm cột is_active để kiểm tra trạng thái hoạt động của người dùng trong quá trình đăng nhập
        query = "SELECT id, username, name, email, role, identity, current_semester_id, password, is_active FROM users WHERE (id = %s OR email = %s OR identity = %s OR username = %s) AND password = %s"
        cursor.execute(query, (req.identity, req.identity, req.identity, req.identity, req.password))
        user = cursor.fetchone()
        
        if user:
            # KIỂM TRA TÀI KHOẢN CÓ BỊ KHÓA KHÔNG
            if not bool(user.get("is_active", 1)):
                cursor.close()
                conn.close()
                raise HTTPException(status_code=403, detail="Tài khoản của bạn đã bị khóa.")
            
            course_ids = []
            if user['role'] == 'student':
                cursor.execute("SELECT course_id FROM student_courses WHERE user_id = %s", (user['id'],))
            elif user['role'] == 'lecturer':
                cursor.execute("SELECT course_id FROM lecturer_courses WHERE user_id = %s", (user['id'],))
            
            if user['role'] in ['student', 'lecturer']:
                course_ids = [c['course_id'] for c in cursor.fetchall()]
            
            cursor.close()
            conn.close()
            return map_user(user, course_ids)
            
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except HTTPException as he:
        raise he
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=os.getenv("API_HOST", "127.0.0.1"),
        port=int(os.getenv("API_PORT", "8000")),
        reload=False,
    )

@app.get("/users")
def get_users(role: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    # Thêm cột is_active để quản lý trạng thái hoạt động của người dùng, mặc định là True nếu không có trường này trong DB
    if role:
        cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id, is_active FROM users WHERE role = %s", (role,))
    else:
        cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id, is_active FROM users")
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
        query = "INSERT INTO users (id, username, name, email, password, role, identity, current_semester_id, is_active) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (user.id, user.username or user.id, user.name, user.email, user.password or '123', user.role, user.identity, user.currentSemesterId, user.isActive))

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
        if err.errno == 1062:
            msg = str(err.msg)
            if "username" in msg: raise HTTPException(status_code=400, detail="Tên đăng nhập đã tồn tại.")
            if "email" in msg: raise HTTPException(status_code=400, detail="Email này đã được sử dụng.")
            if "identity" in msg: raise HTTPException(status_code=400, detail="Mã số định danh đã tồn tại.")
        raise HTTPException(status_code=400, detail=str(err))

@app.put("/users/{user_id}", response_model=UserBase)
def update_user(user_id: str, user: UserBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        conn.start_transaction()
        query = "UPDATE users SET username=%s, name=%s, email=%s, role=%s, identity=%s, current_semester_id=%s, is_active=%s WHERE id=%s"
        cursor.execute(query, (user.username or user.id, user.name, user.email, user.role, user.identity, user.currentSemesterId, user.isActive, user_id))

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
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/users/{user_id}")
def delete_user(user_id: str):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM student_courses WHERE user_id = %s", (user_id,))
        cursor.execute("DELETE FROM lecturer_courses WHERE user_id = %s", (user_id,))
        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "User deleted"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/change-password")
def change_password(data: dict = Body(...)):
    user_id = data.get("user_id")
    old_password = data.get("old_password")
    new_password = data.get("new_password")
    if not user_id: raise HTTPException(status_code=400, detail="Thiếu user_id")
    
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, password FROM users WHERE id = %s OR identity = %s", (user_id, user_id))
        user = cursor.fetchone()
        if not user: raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")
        if user[1] != old_password: raise HTTPException(status_code=400, detail="Mật khẩu cũ không chính xác")
        
        cursor.execute("UPDATE users SET password = %s WHERE id = %s", (new_password, user[0]))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Đổi mật khẩu thành công"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Semesters ---
@app.get("/semesters")
def get_semesters():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM semesters")
    rows = cursor.fetchall()
    semesters = [{"id": r["id"], "name": r["name"], "isActive": bool(r["is_active"])} for r in rows]
    cursor.close()
    conn.close()
    return semesters

@app.post("/semesters")
def create_semester(sem: SemesterBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        if sem.isActive: cursor.execute("UPDATE semesters SET is_active = FALSE")
        cursor.execute("INSERT INTO semesters (id, name, is_active) VALUES (%s, %s, %s)", (sem.id, sem.name, sem.isActive))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Semester created"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/semesters/{sem_id}/toggle-active")
def toggle_semester_active(sem_id: str):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("UPDATE semesters SET is_active = FALSE")
        cursor.execute("UPDATE semesters SET is_active = TRUE WHERE id = %s", (sem_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Semester activated"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Courses ---
@app.get("/courses")
def get_courses():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM courses")
    rows = cursor.fetchall()
    courses = [{"id": r["id"], "name": r["name"], "code": r["code"], "semesterId": r["semester_id"]} for r in rows]
    cursor.close()
    conn.close()
    return courses

@app.post("/courses")
def create_course(course: CourseBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO courses (id, name, code, semester_id) VALUES (%s, %s, %s, %s)", (course.id, course.name, course.code, course.semesterId))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Course created"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/courses/{course_id}")
def delete_course(course_id: str):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM courses WHERE id = %s", (course_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Course deleted"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Topics ---
@app.get("/topics")
def get_topics(lecturer_id: Optional[str] = None, course_id: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT * FROM topics WHERE 1=1"
    params = []
    if lecturer_id:
        query += " AND lecturer_id = %s"
        params.append(lecturer_id)
    if course_id:
        query += " AND course_id = %s"
        params.append(course_id)
    query += " ORDER BY created_at DESC"
    cursor.execute(query, tuple(params))
    topics = [map_topic(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return topics

@app.get("/topics/available")
def get_available_topics(course_id: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    query = """
        SELECT * FROM topics
        WHERE current_groups < max_groups
          AND (start_time IS NULL OR start_time <= NOW())
          AND (end_time IS NULL OR end_time >= NOW())
    """
    params = []
    if course_id:
        query += " AND course_id = %s"
        params.append(course_id)
    query += " ORDER BY created_at DESC"
    cursor.execute(query, tuple(params))
    topics = [map_topic(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return topics

@app.get("/topics/{topic_id}")
def get_topic(topic_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM topics WHERE id = %s", (topic_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Không tìm thấy đề tài")
    return map_topic(row)

@app.post("/topics")
def create_topic(topic: TopicBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        ensure_lecturer_teaches_course(cursor, topic.lecturerId, topic.courseId)
        query = """
            INSERT INTO topics (title, description, lecturer_id, course_id, max_groups, start_time, end_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            topic.title,
            topic.description,
            topic.lecturerId,
            topic.courseId,
            topic.maxGroups,
            topic.startTime,
            topic.endTime,
        ))
        topic_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        return {"id": str(topic_id), "message": "Topic created"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/topics/{topic_id}")
def update_topic(topic_id: int, topic: TopicBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM topics WHERE id=%s", (topic_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy đề tài")
        ensure_lecturer_teaches_course(cursor, topic.lecturerId, topic.courseId)
        query = """
            UPDATE topics
            SET title=%s, description=%s, lecturer_id=%s, course_id=%s,
                max_groups=%s, start_time=%s, end_time=%s
            WHERE id=%s
        """
        cursor.execute(query, (
            topic.title,
            topic.description,
            topic.lecturerId,
            topic.courseId,
            topic.maxGroups,
            topic.startTime,
            topic.endTime,
            topic_id,
        ))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic updated"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/topics/{topic_id}")
def delete_topic(topic_id: int):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("UPDATE `groups` SET topic_id = NULL, status = 'creating', is_locked = FALSE WHERE topic_id = %s AND status <> 'approved'", (topic_id,))
        cursor.execute("DELETE FROM topics WHERE id = %s", (topic_id,))
        if cursor.rowcount == 0:
            conn.rollback()
            raise HTTPException(status_code=404, detail="Không tìm thấy đề tài")
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic deleted"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Groups ---
@app.get("/groups")
def get_groups(course_id: Optional[str] = None, search: Optional[str] = None, topic_id: Optional[str] = None, lecturer_id: Optional[str] = None, status: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT g.* FROM `groups` g"
    params = []
    if lecturer_id:
        query += " JOIN topics t ON g.topic_id = t.id"
    query += " WHERE 1=1"
    if course_id: query += " AND g.course_id = %s"; params.append(course_id)
    if topic_id: query += " AND g.topic_id = %s"; params.append(topic_id)
    if lecturer_id: query += " AND t.lecturer_id = %s"; params.append(lecturer_id)
    if status: query += " AND g.status = %s"; params.append(status)
    if search: query += " AND g.name LIKE %s"; params.append(f"%{search}%")
    query += " ORDER BY CASE WHEN g.status = 'pending_approval' THEN 0 ELSE 1 END, g.created_at DESC"
    cursor.execute(query, tuple(params))
    rows = cursor.fetchall()
    groups = []
    for row in rows:
        member_ids, pending_member_ids = get_group_members(cursor, row["id"])
        groups.append(map_group(row, member_ids, pending_member_ids))
    cursor.close()
    conn.close()
    return groups

@app.get("/groups/{group_id}")
def get_group(group_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
    row = cursor.fetchone()
    if not row:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
    member_ids, pending_member_ids = get_group_members(cursor, group_id)
    result = map_group(row, member_ids, pending_member_ids)
    cursor.close()
    conn.close()
    return result

@app.post("/groups")
def create_group(group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT gm.group_id FROM group_members gm
            JOIN `groups` g ON gm.group_id = g.id
            WHERE gm.user_id = %s AND g.course_id = %s AND gm.status IN ('member', 'pending')
        """, (group.leaderId, group.courseId))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Bạn đã tham gia hoặc đang chờ duyệt ở một nhóm khác trong môn học này.")

        query = """
            INSERT INTO `groups` (name, description, leader_id, course_id, max_members, min_members, topic_id, status, is_locked)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            group.name,
            group.description,
            group.leaderId,
            group.courseId,
            group.maxMembers,
            group.minMembers,
            group.topicId,
            group.status,
            group.isLocked,
        ))
        group_id = cursor.lastrowid
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, group.leaderId))
        conn.commit()
        cursor.close()
        conn.close()
        return {"id": str(group_id), "message": "Group created"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/groups/{group_id}")
def update_group(group_id: int, group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM `groups` WHERE id=%s", (group_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        cursor.execute("""
            UPDATE `groups`
            SET name=%s, description=%s, leader_id=%s, course_id=%s,
                max_members=%s, min_members=%s, topic_id=%s, status=%s, is_locked=%s
            WHERE id=%s
        """, (
            group.name,
            group.description,
            group.leaderId,
            group.courseId,
            group.maxMembers,
            group.minMembers,
            group.topicId,
            group.status,
            group.isLocked,
            group_id,
        ))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Group updated"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/join")
def join_group(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa, không thể xin tham gia.")

        cursor.execute("""
            SELECT gm.group_id FROM group_members gm
            JOIN `groups` g ON gm.group_id = g.id
            WHERE gm.user_id = %s AND g.course_id = %s AND gm.status IN ('member', 'pending')
        """, (user_id, group["course_id"]))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Bạn đã tham gia hoặc đang chờ duyệt ở một nhóm khác trong môn học này.")

        cursor.execute("SELECT COUNT(*) AS total FROM group_members WHERE group_id = %s AND status = 'member'", (group_id,))
        if cursor.fetchone()["total"] >= group["max_members"]:
            raise HTTPException(status_code=400, detail="Nhóm đã đủ số lượng thành viên.")

        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'pending')", (group_id, user_id))
        create_notification(
            cursor,
            group["leader_id"],
            "Yêu cầu tham gia nhóm",
            f"Sinh viên {user_id} muốn tham gia nhóm {group['name']}.",
            "join_request",
            {"groupId": str(group_id), "userId": user_id},
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Join request sent"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/approve-member")
def approve_member(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa đề tài, không thể duyệt thành viên.")
        cursor.execute("UPDATE group_members SET status='member' WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        if cursor.rowcount == 0:
            cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, user_id))
        create_notification(
            cursor,
            user_id,
            "Yêu cầu tham gia được duyệt",
            f"Bạn đã được duyệt vào nhóm {group['name']}.",
            "join_approved",
            {"groupId": str(group_id)},
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Member approved"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/groups/{group_id}/members/{user_id}")
def remove_member(group_id: int, user_id: str):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa đề tài, không thể thay đổi thành viên.")
        cursor.execute("SELECT status FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        member = cursor.fetchone()
        cursor.execute("DELETE FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        if member:
            title = "Yêu cầu tham gia bị từ chối" if member["status"] == "pending" else "Bạn đã bị xóa khỏi nhóm"
            message = f"Yêu cầu tham gia nhóm {group['name']} đã bị từ chối." if member["status"] == "pending" else f"Bạn đã được xóa khỏi nhóm {group['name']}."
            create_notification(cursor, user_id, title, message, "join_rejected", {"groupId": str(group_id)})
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Member removed"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/register-topic")
def register_topic(group_id: int, req: RegisterTopicRequest):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["leader_id"] != req.leaderId:
            raise HTTPException(status_code=403, detail="Chỉ trưởng nhóm mới được đăng ký đề tài.")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa, không thể đổi đề tài.")

        cursor.execute("SELECT * FROM topics WHERE id = %s", (req.topicId,))
        topic = cursor.fetchone()
        if not topic:
            raise HTTPException(status_code=404, detail="Không tìm thấy đề tài")
        if topic["course_id"] != group["course_id"]:
            raise HTTPException(status_code=400, detail="Đề tài không thuộc môn học của nhóm.")
        if topic["current_groups"] >= topic["max_groups"] and str(group.get("topic_id") or "") != req.topicId:
            raise HTTPException(status_code=400, detail="Đề tài này đã đủ số lượng nhóm đăng ký.")

        cursor.execute("SELECT COUNT(*) AS total FROM group_members WHERE group_id=%s AND status='member'", (group_id,))
        if cursor.fetchone()["total"] < group["min_members"]:
            raise HTTPException(status_code=400, detail=f"Nhóm chưa đủ tối thiểu {group['min_members']} thành viên.")

        cursor.execute(
            "UPDATE `groups` SET topic_id=%s, status='pending_approval', is_locked=FALSE WHERE id=%s",
            (req.topicId, group_id),
        )
        create_notification(
            cursor,
            topic["lecturer_id"],
            "Nhóm đăng ký đề tài",
            f"Nhóm {group['name']} đã đăng ký đề tài {topic['title']} và đang chờ duyệt.",
            "topic_registration",
            {"groupId": str(group_id), "topicId": str(req.topicId)},
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic registration sent"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/approve-topic")
def approve_topic_registration(group_id: int, lecturer_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("""
            SELECT g.*, t.title AS topic_title, t.lecturer_id
            FROM `groups` g
            JOIN topics t ON g.topic_id = t.id
            WHERE g.id = %s
        """, (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm hoặc đề tài")
        if group["lecturer_id"] != lecturer_id:
            raise HTTPException(status_code=403, detail="Bạn không phụ trách đề tài này.")
        cursor.execute("UPDATE `groups` SET status='approved', is_locked=TRUE WHERE id=%s", (group_id,))
        notify_group_members(
            cursor,
            group_id,
            "Đề tài đã được duyệt",
            f"Nhóm {group['name']} đã được duyệt đề tài {group['topic_title']}.",
            "topic_approved",
            {"groupId": str(group_id), "topicId": str(group["topic_id"])},
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic registration approved"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/reject-topic")
def reject_topic_registration(group_id: int, lecturer_id: str = Body(..., embed=True), reason: Optional[str] = Body(None, embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("""
            SELECT g.*, t.title AS topic_title, t.lecturer_id
            FROM `groups` g
            JOIN topics t ON g.topic_id = t.id
            WHERE g.id = %s
        """, (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm hoặc đề tài")
        if group["lecturer_id"] != lecturer_id:
            raise HTTPException(status_code=403, detail="Bạn không phụ trách đề tài này.")
        cursor.execute("UPDATE `groups` SET status='rejected', is_locked=FALSE WHERE id=%s", (group_id,))
        extra = f" Lý do: {reason}" if reason else ""
        notify_group_members(
            cursor,
            group_id,
            "Đăng ký đề tài bị từ chối",
            f"Đăng ký đề tài {group['topic_title']} của nhóm {group['name']} đã bị từ chối.{extra}",
            "topic_rejected",
            {"groupId": str(group_id), "topicId": str(group["topic_id"])},
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic registration rejected"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/groups/{group_id}")
def delete_group(group_id: int):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM group_members WHERE group_id = %s", (group_id,))
        cursor.execute("DELETE FROM `groups` WHERE id = %s", (group_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Group deleted successfully"}
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Notifications ---
@app.get("/notifications")
def get_notifications(user_id: str, unread_only: bool = False):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT * FROM notifications WHERE user_id = %s"
    params = [user_id]
    if unread_only:
        query += " AND is_read = FALSE"
    query += " ORDER BY created_at DESC LIMIT 100"
    cursor.execute(query, tuple(params))
    notifications = [map_notification(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return notifications

@app.post("/notifications")
def create_notification_api(notification: NotificationBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        create_notification(
            cursor,
            notification.userId,
            notification.title,
            notification.message,
            notification.type or "general",
            notification.data,
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Notification created"}
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/notifications/{notification_id}/read")
def mark_notification_read(notification_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE notifications SET is_read = TRUE WHERE id = %s", (notification_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notification marked as read"}

@app.put("/notifications/read-all")
def mark_all_notifications_read(user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE notifications SET is_read = TRUE WHERE user_id = %s", (user_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notifications marked as read"}

# --- Settings ---
@app.get("/settings")
def get_settings():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT key_name, value FROM system_settings")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return {r["key_name"]: r["value"] for r in rows}

@app.put("/settings")
def update_settings(settings: SystemSettingsUpdate):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        values = {
            "registration_start": settings.registration_start,
            "registration_end": settings.registration_end,
            "min_members": str(settings.min_members),
            "max_members": str(settings.max_members),
        }
        for key, value in values.items():
            cursor.execute("""
                INSERT INTO system_settings (key_name, value)
                VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE value = VALUES(value)
            """, (key, value))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Settings updated"}
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Admin Dashboard Stats ---
@app.get("/admin/dashboard-stats")
def get_dashboard_stats():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT COUNT(*) as total FROM users WHERE role = 'student'")
    students_count = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM users WHERE role = 'lecturer'")
    lecturers_count = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE status = 'approved'")
    approved_groups = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM `groups`")
    total_groups = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM topics")
    topics_count = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM courses")
    courses_count = cursor.fetchone()['total']
    cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE status = 'pending_approval'")
    pending_groups = cursor.fetchone()['total']
    
    cursor.close()
    conn.close()
    return {
        "students": students_count,
        "lecturers": lecturers_count,
        "totalGroups": total_groups,
        "approvedGroups": approved_groups,
        "topics": topics_count,
        "courses": courses_count,
        "pendingApprovals": pending_groups
    }

# --- API Lấy Dữ Liệu Thống Kê Cho Dashboard ---
@app.get("/admin/statistics")
def get_detailed_statistics():
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor(dictionary=True)
        
        # 1. Thống kê Tổng số nhóm
        cursor.execute("SELECT COUNT(*) as total FROM `groups`")
        total_groups = cursor.fetchone()['total']
        
        # 2. Thống kê Số nhóm đã chốt/đăng ký đề tài thành công (trường topic_id không null)
        cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE status = 'approved'")
        groups_with_topic = cursor.fetchone()['total']
        
        # 3. Thống kê Tổng số đề tài hiện có
        cursor.execute("SELECT COUNT(*) as total FROM topics")
        total_topics = cursor.fetchone()['total']
        
        # 4. Thống kê Số đề tài trống (Chưa có bất kỳ nhóm nào đăng ký chọn)
        cursor.execute("""
            SELECT COUNT(*) as total FROM topics t 
            WHERE t.id NOT IN (SELECT DISTINCT topic_id FROM `groups` WHERE topic_id IS NOT NULL AND status = 'approved')
        """)
        unregistered_topics = cursor.fetchone()['total']
        
        # 5. Lấy danh sách Top các đề tài được quan tâm nhiều nhất (Xếp hạng theo số lượng nhóm đăng ký)
        cursor.execute("""
            SELECT t.title, COUNT(g.id) as group_count 
            FROM topics t 
            LEFT JOIN `groups` g ON t.id = g.topic_id AND g.status = 'approved'
            GROUP BY t.id, t.title 
            ORDER BY group_count DESC 
            LIMIT 5
        """)
        top_topics = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return {
            "totalGroups": total_groups,
            "groupsWithTopic": groups_with_topic,
            "totalTopics": total_topics,
            "unregisteredTopics": unregistered_topics,
            "topTopics": [{"name": r["title"], "count": r["group_count"]} for r in top_topics]
        }
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=500, detail=str(e))
#------------------
# from fastapi import FastAPI, HTTPException, Depends, Body
# from typing import List, Optional
# from pydantic import BaseModel
# from database import get_db_connection, ensure_db_setup
# import mysql.connector
# from fastapi.middleware.cors import CORSMiddleware

# app = FastAPI(title="Hệ thống Đăng ký Đề tài API")

# @app.on_event("startup")
# def startup_event():
#     ensure_db_setup()

# #python3 -m uvicorn main:app --reload
# # --- CORS configuration ---
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # --- Models ---

# class UserBase(BaseModel):
#     id: str
#     username: Optional[str] = None
#     name: str
#     email: str
#     role: str
#     identity: Optional[str] = None
#     password: Optional[str] = None
#     enrolledCourseIds: Optional[List[str]] = []
#     taughtCourseIds: Optional[List[str]] = []
#     currentSemesterId: Optional[str] = None
#     isActive: Optional[bool] = True # Mới: Trạng thái hoạt động của người dùng

# class TopicBase(BaseModel):
#     id: Optional[str] = None
#     title: str
#     description: Optional[str] = ""
#     lecturerId: str
#     courseId: str
#     maxGroups: int = 1
#     currentGroups: int = 0
#     startTime: Optional[str] = None
#     endTime: Optional[str] = None

# class GroupBase(BaseModel):
#     id: Optional[str] = None
#     name: str
#     description: Optional[str] = ""
#     leaderId: str
#     courseId: str
#     maxMembers: int = 5
#     minMembers: int = 2
#     topicId: Optional[str] = None
#     status: str = "creating"
#     isLocked: bool = False

# class RegisterTopicRequest(BaseModel):
#     topicId: str
#     leaderId: str

# class LoginRequest(BaseModel):
#     identity: str
#     password: str

# class SystemSettingsUpdate(BaseModel):
#     registration_start: str
#     registration_end: str
#     min_members: int
#     max_members: int

# class SemesterBase(BaseModel):
#     id: str
#     name: str
#     isActive: bool = False

# class CourseBase(BaseModel):
#     id: str
#     name: str
#     code: str
#     semesterId: Optional[str] = None

# # --- Helper Mappings ---
# def map_user(row, course_ids=None):
#     user_data = {
#         "id": row["id"],
#         "username": row.get("username") or row["id"],
#         "name": row["name"],
#         "email": row["email"],
#         "role": row["role"],
#         "identity": row["identity"],
#         "currentSemesterId": row["current_semester_id"],
#         "isActive": bool(row.get("is_active", 1)) # Mới: Trạng thái hoạt động của người dùng, mặc định là True nếu không có trường này trong DB
#     }
    
#     if row["role"] == 'student':
#         user_data["enrolledCourseIds"] = course_ids if course_ids is not None else []
#     elif row["role"] == 'lecturer':
#         user_data["taughtCourseIds"] = course_ids if course_ids is not None else []
        
#     return user_data

# def map_topic(row):
#     return {
#         "id": str(row["id"]),
#         "title": row["title"],
#         "description": row["description"] or "",
#         "lecturerId": row["lecturer_id"],
#         "courseId": row["course_id"],
#         "maxGroups": row["max_groups"],
#         "currentGroups": row["current_groups"],
#         "startTime": row["start_time"].isoformat() if row["start_time"] else None,
#         "endTime": row["end_time"].isoformat() if row["end_time"] else None
#     }

# def map_group(row):
#     return {
#         "id": str(row["id"]),
#         "name": row["name"],
#         "description": row["description"] or "",
#         "leaderId": row["leader_id"],
#         "courseId": row["course_id"],
#         "maxMembers": row["max_members"],
#         "minMembers": row.get("min_members", 2),
#         "topicId": str(row["topic_id"]) if row["topic_id"] else None,
#         "status": row["status"],
#         "isLocked": bool(row["is_locked"])
#     }

# # --- Routes ---

# @app.get("/")
# def read_root():
#     return {"message": "Welcome to Student Registration API"}

# @app.post("/login")
# def login(req: LoginRequest):
#     conn = get_db_connection()
#     if not conn:
#         raise HTTPException(status_code=500, detail="Database connection failed")
#     try:
#         cursor = conn.cursor(dictionary=True)
#         #Thêm cột is_active để kiểm tra trạng thái hoạt động của người dùng trong quá trình đăng nhập
#         query = "SELECT id, username, name, email, role, identity, current_semester_id, password, is_active FROM users WHERE (id = %s OR email = %s OR identity = %s OR username = %s) AND password = %s"
#         cursor.execute(query, (req.identity, req.identity, req.identity, req.identity, req.password))
#         user = cursor.fetchone()
        
#         if user:
#             # KIỂM TRA TÀI KHOẢN CÓ BỊ KHÓA KHÔNG
#             if not bool(user.get("is_active", 1)):
#                 cursor.close()
#                 conn.close()
#                 raise HTTPException(status_code=403, detail="Tài khoản của bạn đã bị khóa.")
            
#             course_ids = []
#             if user['role'] == 'student':
#                 cursor.execute("SELECT course_id FROM student_courses WHERE user_id = %s", (user['id'],))
#             elif user['role'] == 'lecturer':
#                 cursor.execute("SELECT course_id FROM lecturer_courses WHERE user_id = %s", (user['id'],))
            
#             if user['role'] in ['student', 'lecturer']:
#                 course_ids = [c['course_id'] for c in cursor.fetchall()]
            
#             cursor.close()
#             conn.close()
#             return map_user(user, course_ids)
            
#         cursor.close()
#         conn.close()
#         raise HTTPException(status_code=401, detail="Invalid credentials")
#     except HTTPException as he:
#         raise he
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=500, detail=str(e))

# @app.get("/users")
# def get_users(role: Optional[str] = None):
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     # Thêm cột is_active để quản lý trạng thái hoạt động của người dùng, mặc định là True nếu không có trường này trong DB
#     if role:
#         cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id, is_active FROM users WHERE role = %s", (role,))
#     else:
#         cursor.execute("SELECT id, username, name, email, role, identity, current_semester_id, is_active FROM users")
#     users = cursor.fetchall()

#     mapped_users = []
#     for u in users:
#         course_ids = []
#         if u['role'] == 'student':
#             cursor.execute("SELECT course_id FROM student_courses WHERE user_id = %s", (u['id'],))
#             course_ids = [c['course_id'] for c in cursor.fetchall()]
#         elif u['role'] == 'lecturer':
#             cursor.execute("SELECT course_id FROM lecturer_courses WHERE user_id = %s", (u['id'],))
#             course_ids = [c['course_id'] for c in cursor.fetchall()]
#         mapped_users.append(map_user(u, course_ids))

#     cursor.close()
#     conn.close()
#     return mapped_users

# @app.post("/users", response_model=UserBase)
# def create_user(user: UserBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         conn.start_transaction()
#         query = "INSERT INTO users (id, username, name, email, password, role, identity, current_semester_id, is_active) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"
#         cursor.execute(query, (user.id, user.username or user.id, user.name, user.email, user.password or '123', user.role, user.identity, user.currentSemesterId, user.isActive))

#         if user.role == 'student' and user.enrolledCourseIds:
#             for c_id in user.enrolledCourseIds:
#                 cursor.execute("INSERT INTO student_courses (user_id, course_id) VALUES (%s, %s)", (user.id, c_id))
#         elif user.role == 'lecturer' and user.taughtCourseIds:
#             for c_id in user.taughtCourseIds:
#                 cursor.execute("INSERT INTO lecturer_courses (user_id, course_id) VALUES (%s, %s)", (user.id, c_id))

#         conn.commit()
#         cursor.close()
#         conn.close()
#         return user
#     except mysql.connector.Error as err:
#         if conn and conn.is_connected(): conn.rollback(); conn.close()
#         if err.errno == 1062:
#             msg = str(err.msg)
#             if "username" in msg: raise HTTPException(status_code=400, detail="Tên đăng nhập đã tồn tại.")
#             if "email" in msg: raise HTTPException(status_code=400, detail="Email này đã được sử dụng.")
#             if "identity" in msg: raise HTTPException(status_code=400, detail="Mã số định danh đã tồn tại.")
#         raise HTTPException(status_code=400, detail=str(err))

# @app.put("/users/{user_id}", response_model=UserBase)
# def update_user(user_id: str, user: UserBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         conn.start_transaction()
#         query = "UPDATE users SET username=%s, name=%s, email=%s, role=%s, identity=%s, current_semester_id=%s, is_active=%s WHERE id=%s"
#         cursor.execute(query, (user.username or user.id, user.name, user.email, user.role, user.identity, user.currentSemesterId, user.isActive, user_id))

#         if user.role == 'student':
#             cursor.execute("DELETE FROM student_courses WHERE user_id = %s", (user_id,))
#             if user.enrolledCourseIds:
#                 for c_id in user.enrolledCourseIds:
#                     cursor.execute("INSERT INTO student_courses (user_id, course_id) VALUES (%s, %s)", (user_id, c_id))
#         elif user.role == 'lecturer':
#             cursor.execute("DELETE FROM lecturer_courses WHERE user_id = %s", (user_id,))
#             if user.taughtCourseIds:
#                 for c_id in user.taughtCourseIds:
#                     cursor.execute("INSERT INTO lecturer_courses (user_id, course_id) VALUES (%s, %s)", (user_id, c_id))

#         conn.commit()
#         cursor.close()
#         conn.close()
#         return user
#     except Exception as e:
#         if conn and conn.is_connected(): conn.rollback(); conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.delete("/users/{user_id}")
# def delete_user(user_id: str):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("DELETE FROM student_courses WHERE user_id = %s", (user_id,))
#         cursor.execute("DELETE FROM lecturer_courses WHERE user_id = %s", (user_id,))
#         cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "User deleted"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.post("/change-password")
# def change_password(data: dict = Body(...)):
#     user_id = data.get("user_id")
#     old_password = data.get("old_password")
#     new_password = data.get("new_password")
#     if not user_id: raise HTTPException(status_code=400, detail="Thiếu user_id")
    
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("SELECT id, password FROM users WHERE id = %s OR identity = %s", (user_id, user_id))
#         user = cursor.fetchone()
#         if not user: raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")
#         if user[1] != old_password: raise HTTPException(status_code=400, detail="Mật khẩu cũ không chính xác")
        
#         cursor.execute("UPDATE users SET password = %s WHERE id = %s", (new_password, user[0]))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Đổi mật khẩu thành công"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# # --- Semesters ---
# @app.get("/semesters")
# def get_semesters():
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     cursor.execute("SELECT * FROM semesters")
#     rows = cursor.fetchall()
#     semesters = [{"id": r["id"], "name": r["name"], "isActive": bool(r["is_active"])} for r in rows]
#     cursor.close()
#     conn.close()
#     return semesters

# @app.post("/semesters")
# def create_semester(sem: SemesterBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         if sem.isActive: cursor.execute("UPDATE semesters SET is_active = FALSE")
#         cursor.execute("INSERT INTO semesters (id, name, is_active) VALUES (%s, %s, %s)", (sem.id, sem.name, sem.isActive))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Semester created"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.put("/semesters/{sem_id}/toggle-active")
# def toggle_semester_active(sem_id: str):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("UPDATE semesters SET is_active = FALSE")
#         cursor.execute("UPDATE semesters SET is_active = TRUE WHERE id = %s", (sem_id,))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Semester activated"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# # --- Courses ---
# @app.get("/courses")
# def get_courses():
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     cursor.execute("SELECT * FROM courses")
#     rows = cursor.fetchall()
#     courses = [{"id": r["id"], "name": r["name"], "code": r["code"], "semesterId": r["semester_id"]} for r in rows]
#     cursor.close()
#     conn.close()
#     return courses

# @app.post("/courses")
# def create_course(course: CourseBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("INSERT INTO courses (id, name, code, semester_id) VALUES (%s, %s, %s, %s)", (course.id, course.name, course.code, course.semesterId))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Course created"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.delete("/courses/{course_id}")
# def delete_course(course_id: str):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("DELETE FROM courses WHERE id = %s", (course_id,))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Course deleted"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# # --- Topics ---
# @app.get("/topics")
# def get_topics(lecturer_id: Optional[str] = None):
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     if lecturer_id:
#         cursor.execute("SELECT * FROM topics WHERE lecturer_id = %s", (lecturer_id,))
#     else:
#         cursor.execute("SELECT * FROM topics")
#     topics = [map_topic(r) for r in cursor.fetchall()]
#     cursor.close()
#     conn.close()
#     return topics

# @app.post("/topics")
# def create_topic(topic: TopicBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         query = "INSERT INTO topics (title, description, lecturer_id, max_groups) VALUES (%s, %s, %s, %s)"
#         cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.maxGroups))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Topic created"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# # --- Groups ---
# @app.get("/groups")
# def get_groups(course_id: Optional[str] = None, search: Optional[str] = None, topic_id: Optional[str] = None):
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     query = "SELECT * FROM `groups` WHERE 1=1"
#     params = []
#     if course_id: query += " AND course_id = %s"; params.append(course_id)
#     if topic_id: query += " AND topic_id = %s"; params.append(topic_id)
#     if search: query += " AND name LIKE %s"; params.append(f"%{search}%")
#     cursor.execute(query, tuple(params))
#     groups = [map_group(r) for r in cursor.fetchall()]
#     cursor.close()
#     conn.close()
#     return groups

# @app.post("/groups")
# def create_group(group: GroupBase):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         query = "INSERT INTO `groups` (name, description, leader_id, course_id, max_members, topic_id) VALUES (%s, %s, %s, %s, %s, %s)"
#         cursor.execute(query, (group.name, group.description, group.leaderId, group.courseId, group.maxMembers, group.topicId))
#         group_id = cursor.lastrowid
#         cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, group.leaderId))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"id": str(group_id), "message": "Group created"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.post("/groups/{group_id}/join")
# def join_group(group_id: int, user_id: str = Body(..., embed=True)):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'pending')", (group_id, user_id))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Join request sent"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# @app.post("/groups/{group_id}/approve-member")
# def approve_member(group_id: int, user_id: str = Body(..., embed=True)):
#     conn = get_db_connection()
#     cursor = conn.cursor()
#     cursor.execute("UPDATE group_members SET status='member' WHERE group_id=%s AND user_id=%s", (group_id, user_id))
#     conn.commit()
#     cursor.close()
#     conn.close()
#     return {"message": "Member approved"}

# @app.delete("/groups/{group_id}/members/{user_id}")
# def remove_member(group_id: int, user_id: str):
#     conn = get_db_connection()
#     cursor = conn.cursor()
#     cursor.execute("DELETE FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
#     conn.commit()
#     cursor.close()
#     conn.close()
#     return {"message": "Member removed"}

# @app.delete("/groups/{group_id}")
# def delete_group(group_id: int):
#     conn = get_db_connection()
#     try:
#         cursor = conn.cursor()
#         cursor.execute("DELETE FROM group_members WHERE group_id = %s", (group_id,))
#         cursor.execute("DELETE FROM `groups` WHERE id = %s", (group_id,))
#         conn.commit()
#         cursor.close()
#         conn.close()
#         return {"message": "Group deleted successfully"}
#     except Exception as e:
#         if conn and conn.is_connected(): conn.rollback(); conn.close()
#         raise HTTPException(status_code=400, detail=str(e))

# # --- Admin Dashboard Stats ---
# @app.get("/admin/dashboard-stats")
# def get_dashboard_stats():
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     cursor.execute("SELECT COUNT(*) as total FROM users WHERE role = 'student'")
#     students_count = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM users WHERE role = 'lecturer'")
#     lecturers_count = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE status = 'approved'")
#     approved_groups = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM `groups`")
#     total_groups = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM topics")
#     topics_count = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM courses")
#     courses_count = cursor.fetchone()['total']
#     cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE status = 'pending'")
#     pending_groups = cursor.fetchone()['total']
    
#     cursor.close()
#     conn.close()
#     return {
#         "students": students_count,
#         "lecturers": lecturers_count,
#         "totalGroups": total_groups,
#         "approvedGroups": approved_groups,
#         "topics": topics_count,
#         "courses": courses_count,
#         "pendingApprovals": pending_groups
#     }

# # --- API Lấy Dữ Liệu Thống Kê Cho Dashboard ---
# @app.get("/admin/statistics")
# def get_detailed_statistics():
#     conn = get_db_connection()
#     if not conn:
#         raise HTTPException(status_code=500, detail="Database connection failed")
#     try:
#         cursor = conn.cursor(dictionary=True)
        
#         # 1. Thống kê Tổng số nhóm
#         cursor.execute("SELECT COUNT(*) as total FROM `groups`")
#         total_groups = cursor.fetchone()['total']
        
#         # 2. Thống kê Số nhóm đã chốt/đăng ký đề tài thành công (trường topic_id không null)
#         cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE topic_id IS NOT NULL")
#         groups_with_topic = cursor.fetchone()['total']
        
#         # 3. Thống kê Tổng số đề tài hiện có
#         cursor.execute("SELECT COUNT(*) as total FROM topics")
#         total_topics = cursor.fetchone()['total']
        
#         # 4. Thống kê Số đề tài trống (Chưa có bất kỳ nhóm nào đăng ký chọn)
#         cursor.execute("""
#             SELECT COUNT(*) as total FROM topics t 
#             WHERE t.id NOT IN (SELECT DISTINCT topic_id FROM `groups` WHERE topic_id IS NOT NULL)
#         """)
#         unregistered_topics = cursor.fetchone()['total']
        
#         # 5. Lấy danh sách Top các đề tài được quan tâm nhiều nhất (Xếp hạng theo số lượng nhóm đăng ký)
#         cursor.execute("""
#             SELECT t.title, COUNT(g.id) as group_count 
#             FROM topics t 
#             LEFT JOIN `groups` g ON t.id = g.topic_id 
#             GROUP BY t.id, t.title 
#             ORDER BY group_count DESC 
#             LIMIT 5
#         """)
#         top_topics = cursor.fetchall()
        
#         cursor.close()
#         conn.close()
        
#         return {
#             "totalGroups": total_groups,
#             "groupsWithTopic": groups_with_topic,
#             "totalTopics": total_topics,
#             "unregisteredTopics": unregistered_topics,
#             "topTopics": [{"name": r["title"], "count": r["group_count"]} for r in top_topics]
#         }
#     except Exception as e:
#         if conn and conn.is_connected(): conn.close()
#         raise HTTPException(status_code=500, detail=str(e))
