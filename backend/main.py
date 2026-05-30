from fastapi import FastAPI, HTTPException, Depends, Body
from typing import List, Optional
from pydantic import BaseModel
from database import get_db_connection
import mysql.connector

app = FastAPI(title="Hệ thống Đăng ký Đề tài API")

# --- Models ---

class UserBase(BaseModel):
    id: str
    name: str
    email: str
    role: str
    identity: Optional[str] = None
    password: Optional[str] = None

class TopicBase(BaseModel):
    id: Optional[str] = None # String ID for Flutter
    title: str
    description: Optional[str] = ""
    lecturerId: str # lecturer_id in DB
    maxGroups: int = 1 # max_groups in DB
    currentGroups: int = 0 # current_groups in DB
    startTime: Optional[str] = None
    endTime: Optional[str] = None

class GroupBase(BaseModel):
    id: Optional[str] = None
    name: str
    description: Optional[str] = ""
    leaderId: str # leader_id in DB
    maxMembers: int = 5 # max_members in DB
    topicId: Optional[str] = None # topic_id in DB
    status: str = "pending_approval"
    isLocked: bool = False # is_locked in DB

class LoginRequest(BaseModel):
    identity: str
    password: str

# --- Helper Mappings ---

def map_topic(row):
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "description": row["description"] or "",
        "lecturerId": row["lecturer_id"],
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
        "maxMembers": row["max_members"],
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
        query = "SELECT id, name, email, role, identity FROM users WHERE (id = %s OR email = %s OR identity = %s) AND password = %s"
        cursor.execute(query, (req.identity, req.identity, req.identity, req.password))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        if user:
            print(f"DEBUG: Login successful for user: {user['name']}")
            return user
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users", response_model=List[UserBase])
def get_users(role: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if role:
        cursor.execute("SELECT id, name, email, role, identity FROM users WHERE role = %s", (role,))
    else:
        cursor.execute("SELECT id, name, email, role, identity FROM users")
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    return users

@app.post("/users", response_model=UserBase)
def create_user(user: UserBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        # Check if email or identity already exists
        cursor.execute("SELECT id FROM users WHERE email = %s OR identity = %s", (user.email, user.identity))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email hoặc MSSV đã tồn tại trong hệ thống")
        
        # Insert new user
        query = "INSERT INTO users (id, name, email, password, role, identity) VALUES (%s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (user.id, user.name, user.email, user.password or '123', user.role, user.identity))
        conn.commit()
        cursor.close()
        conn.close()
        return user
    except mysql.connector.Error as err:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=f"Lỗi cơ sở dữ liệu: {str(err)}")
    except HTTPException as e:
        if conn and conn.is_connected(): conn.close()
        raise e

@app.put("/users/{user_id}", response_model=UserBase)
def update_user(user_id: str, user: UserBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "UPDATE users SET name=%s, email=%s, role=%s, identity=%s WHERE id=%s"
        cursor.execute(query, (user.name, user.email, user.role, user.identity, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return user
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
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

@app.post("/change-password")
def change_password(data: dict = Body(...)):
    user_id = data.get("user_id")
    old_password = data.get("old_password")
    new_password = data.get("new_password")
    print(f"DEBUG: Change password attempt for user: {user_id}")
    if not user_id:
        raise HTTPException(status_code=400, detail="Thiếu user_id")
    
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, password FROM users WHERE id = %s OR identity = %s",
            (user_id, user_id)
        )
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")
        
        if user[1] != old_password:
            raise HTTPException(status_code=400, detail="Mật khẩu cũ không chính xác")
        
        cursor.execute("UPDATE users SET password = %s WHERE id = %s", (new_password, user[0]))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Đổi mật khẩu thành công"}
    except HTTPException as e:
        if conn and conn.is_connected(): conn.close()
        raise e
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))
    
# --- Topic Routes ---

@app.get("/topics")
def get_topics(lecturer_id: Optional[str] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if lecturer_id:
        cursor.execute("SELECT * FROM topics WHERE lecturer_id = %s", (lecturer_id,))
    else:
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
        query = "INSERT INTO topics (title, description, lecturer_id, max_groups, start_time, end_time) VALUES (%s, %s, %s, %s, %s, %s)"
        print(f"DEBUG: Executing query: {query}")
        cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.maxGroups, topic.startTime, topic.endTime))
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
        query = "UPDATE topics SET title=%s, description=%s, lecturer_id=%s, max_groups=%s, start_time=%s, end_time=%s WHERE id=%s"
        cursor.execute(query, (topic.title, topic.description, topic.lecturerId, topic.maxGroups, topic.startTime, topic.endTime, topic_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Topic updated"}
    except Exception as e:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/topics/{topic_id}")
def get_topic(topic_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM topics WHERE id = %s", (topic_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if row:
        return map_topic(row)
    raise HTTPException(status_code=404, detail="Topic not found")

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
def get_groups(topic_id: Optional[int] = None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if topic_id:
        cursor.execute("SELECT * FROM `groups` WHERE topic_id = %s", (topic_id,))
    else:
        cursor.execute("SELECT * FROM `groups`")
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

@app.get("/groups/{group_id}")
def get_group(group_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
    row = cursor.fetchone()
    if not row:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Group not found")
    
    g = map_group(row)
    cursor.execute("""
        SELECT u.id, u.name, u.identity, gm.status 
        FROM group_members gm 
        JOIN users u ON gm.user_id = u.id 
        WHERE gm.group_id = %s
    """, (group_id,))
    members = cursor.fetchall()
    g['memberIds'] = [m['id'] for m in members if m['status'] == 'member']
    g['pendingMemberIds'] = [m['id'] for m in members if m['status'] == 'pending']
    
    cursor.close()
    conn.close()
    return g

@app.post("/groups")
def create_group(group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "INSERT INTO `groups` (name, description, leader_id, max_members, topic_id) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(query, (group.name, group.description, group.leaderId, group.maxMembers, group.topicId))
        group_id = cursor.lastrowid
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'member')", (group_id, group.leaderId))
        conn.commit()
        cursor.close()
        conn.close()
        return {"id": str(group_id), "message": "Group created successfully"}
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/groups/{group_id}")
def update_group(group_id: int, group: GroupBase):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "UPDATE `groups` SET name=%s, description=%s, max_members=%s, topic_id=%s, status=%s, is_locked=%s WHERE id=%s"
        cursor.execute(query, (group.name, group.description, group.maxMembers, group.topicId, group.status, group.isLocked, group_id))
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
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT is_locked, max_members, (SELECT COUNT(*) FROM group_members WHERE group_id=%s AND status='member') as current_members FROM `groups` WHERE id=%s", (group_id, group_id))
        group_info = cursor.fetchone()
        if not group_info: raise HTTPException(status_code=404, detail="Group not found")
        if group_info[0]: raise HTTPException(status_code=400, detail="Group is locked")
        if group_info[2] >= group_info[1]: raise HTTPException(status_code=400, detail="Group is full")
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'pending')", (group_id, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Join request sent"}
    except mysql.connector.Error as err:
        if conn and conn.is_connected(): conn.close()
        raise HTTPException(status_code=400, detail="Already in this group or request pending")

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
        # Delete member associations first
        cursor.execute("DELETE FROM group_members WHERE group_id = %s", (group_id,))
        # Delete the group
        cursor.execute("DELETE FROM `groups` WHERE id = %s", (group_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Group deleted successfully"}
    except Exception as e:
        if conn and conn.is_connected(): 
            conn.rollback()
            conn.close()
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
