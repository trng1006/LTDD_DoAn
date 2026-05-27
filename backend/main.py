from fastapi import FastAPI, HTTPException, Depends
from typing import List, Optional
from pydantic import BaseModel
from database import get_db_connection

app = FastAPI(title="Hệ thống Đăng ký Đề tài API")

# --- Models ---
class UserBase(BaseModel):
    id: str
    name: str
    email: str
    role: str
    identity: Optional[str] = None

class TopicBase(BaseModel):
    id: Optional[int] = None
    title: str
    description: str
    lecturer_id: str
    max_groups: int
    current_groups: int = 0

# --- Routes ---

@app.get("/")
def read_root():
    return {"message": "Welcome to Student Registration API"}

@app.post("/login")
def login(data: dict):
    # Log để debug
    print(f"DEBUG: Login attempt with identity: {data.get('identity')}")
    
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cursor = conn.cursor(dictionary=True)
        # Truy vấn kiểm tra cả ID, Email và Identity (MSSV/MSGV)
        query = "SELECT id, name, email, role, identity FROM users WHERE (id = %s OR email = %s OR identity = %s) AND password = %s"
        cursor.execute(query, (data['identity'], data['identity'], data['identity'], data['password']))
        user = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if user:
            print(f"DEBUG: Login successful for user: {user['name']}")
            return user
        
        print(f"DEBUG: Login failed - Invalid credentials for: {data.get('identity')}")
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        if conn.is_connected():
            conn.close()
        print(f"DEBUG: Login Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/topics", response_model=List[TopicBase])
def get_topics():
    conn = get_db_connection()
    if not conn:
        return []
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM topics")
    topics = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return topics

@app.get("/groups")
def get_groups():
    conn = get_db_connection()
    if not conn:
        return []
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM groups")
    groups = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return groups

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
