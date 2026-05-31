from fastapi import FastAPI, HTTPException, Depends, Body
from typing import List, Optional
from pydantic import BaseModel
from database import get_db_connection
import mysql.connector
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Hệ thống Đăng ký Đề tài API")
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
def get_topics(lecturer_id: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if lecturer_id:
        cursor.execute("SELECT * FROM topics WHERE lecturer_id = %s", (lecturer_id,))
    else:
        cursor.execute("SELECT * FROM topics")
    topics = [map_topic(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return topics

@app.post("/topics")
def create_topic(topic: TopicBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "INSERT INTO topics (title, description, lecturer_id, max_groups) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.maxGroups))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic created"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

# --- Groups ---
@app.get("/groups")
def get_groups(course_id: Optional[str] = None, search: Optional[str] = None, topic_id: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT * FROM `groups` WHERE 1=1"
    params = []
    if course_id: query += " AND course_id = %s"; params.append(course_id)
    if topic_id: query += " AND topic_id = %s"; params.append(topic_id)
    if search: query += " AND name LIKE %s"; params.append(f"%{search}%")
    cursor.execute(query, tuple(params))
    groups = [map_group(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return groups

@app.post("/groups")
def create_group(group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "INSERT INTO `groups` (name, description, leader_id, course_id, max_members, topic_id) VALUES (%s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (group.name, group.description, group.leaderId, group.courseId, group.maxMembers, group.topicId))
        group_id = cursor.lastrowid
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, group.leaderId))
        conn.commit()
        cursor.close()
        conn.close()
        return {"id": str(group_id), "message": "Group created"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/join")
def join_group(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'pending')", (group_id, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Join request sent"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

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
    cursor.execute("SELECT COUNT(*) as total FROM topics")
    topics_count = cursor.fetchone()['total']
    cursor.close()
    conn.close()
    return {
        "students": students_count,
        "lecturers": lecturers_count,
        "approvedGroups": approved_groups,
        "topics": topics_count
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
        cursor.execute("SELECT COUNT(*) as total FROM `groups` WHERE topic_id IS NOT NULL")
        groups_with_topic = cursor.fetchone()['total']
        
        # 3. Thống kê Tổng số đề tài hiện có
        cursor.execute("SELECT COUNT(*) as total FROM topics")
        total_topics = cursor.fetchone()['total']
        
        # 4. Thống kê Số đề tài trống (Chưa có bất kỳ nhóm nào đăng ký chọn)
        cursor.execute("""
            SELECT COUNT(*) as total FROM topics t 
            WHERE t.id NOT IN (SELECT DISTINCT topic_id FROM `groups` WHERE topic_id IS NOT NULL)
        """)
        unregistered_topics = cursor.fetchone()['total']
        
        # 5. Lấy danh sách Top các đề tài được quan tâm nhiều nhất (Xếp hạng theo số lượng nhóm đăng ký)
        cursor.execute("""
            SELECT t.title, COUNT(g.id) as group_count 
            FROM topics t 
            LEFT JOIN `groups` g ON t.id = g.topic_id 
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