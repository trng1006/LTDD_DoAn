import re

with open("backend/main.py", "r") as f:
    content = f.read()

# 1. Update map_group
content = content.replace(
    'def map_group(row, member_ids=None, pending_member_ids=None):',
    'def map_group(row, member_ids=None, pending_member_ids=None, invited_member_ids=None):'
)
content = content.replace(
    '"pendingMemberIds": pending_member_ids if pending_member_ids is not None else []',
    '"pendingMemberIds": pending_member_ids if pending_member_ids is not None else [],\n        "invitedMemberIds": invited_member_ids if invited_member_ids is not None else []'
)

# 2. Update get_group_members
old_get_group_members = """def get_group_members(cursor, group_id: int):
    cursor.execute("SELECT user_id, status FROM group_members WHERE group_id = %s", (group_id,))
    rows = cursor.fetchall()
    member_ids = [r["user_id"] for r in rows if r["status"] == "member"]
    pending_member_ids = [r["user_id"] for r in rows if r["status"] == "pending"]
    return member_ids, pending_member_ids"""

new_get_group_members = """def get_group_members(cursor, group_id: int):
    cursor.execute("SELECT user_id, status FROM group_members WHERE group_id = %s", (group_id,))
    rows = cursor.fetchall()
    member_ids = [r["user_id"] for r in rows if r["status"] == "member"]
    pending_member_ids = [r["user_id"] for r in rows if r["status"] == "pending"]
    invited_member_ids = [r["user_id"] for r in rows if r["status"] == "invited"]
    return member_ids, pending_member_ids, invited_member_ids"""
content = content.replace(old_get_group_members, new_get_group_members)

# 3. Update get_groups call mapping
content = content.replace(
    'member_ids, pending_member_ids = get_group_members(cursor, row["id"])',
    'member_ids, pending_member_ids, invited_member_ids = get_group_members(cursor, row["id"])'
)
content = content.replace(
    'groups.append(map_group(row, member_ids, pending_member_ids))',
    'groups.append(map_group(row, member_ids, pending_member_ids, invited_member_ids))'
)

# 4. Update get_my_groups call mapping
content = content.replace(
    '        member_ids, pending_member_ids = get_group_members(cursor, row["id"])\n        groups.append(map_group(row, member_ids, pending_member_ids))',
    '        member_ids, pending_member_ids, invited_member_ids = get_group_members(cursor, row["id"])\n        groups.append(map_group(row, member_ids, pending_member_ids, invited_member_ids))'
)

# 5. Add new endpoints
new_endpoints = """
@app.post("/groups/{group_id}/invite-member")
def invite_member(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa, không thể mời thành viên.")
        
        cursor.execute("SELECT COUNT(*) AS total FROM group_members WHERE group_id = %s AND status = 'member'", (group_id,))
        if cursor.fetchone()["total"] >= group["max_members"]:
            raise HTTPException(status_code=400, detail="Nhóm đã đủ số lượng thành viên.")

        cursor.execute("SELECT status FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        member = cursor.fetchone()
        if member:
            if member["status"] == "member":
                raise HTTPException(status_code=400, detail="Sinh viên đã ở trong nhóm.")
            elif member["status"] == "pending":
                raise HTTPException(status_code=400, detail="Sinh viên đang chờ duyệt.")
            elif member["status"] == "invited":
                raise HTTPException(status_code=400, detail="Sinh viên đã được mời trước đó.")
        
        cursor.execute("INSERT INTO group_members (group_id, user_id, status) VALUES (%s, %s, 'invited')", (group_id, user_id))
        create_notification(
            cursor,
            user_id,
            "Lời mời tham gia nhóm",
            f"Nhóm {group['name']} mời bạn tham gia nhóm.",
            "group_invite",
            {"groupId": str(group_id)}
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Đã gửi lời mời"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/accept-invite")
def accept_invite(group_id: int, user_id: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        if group["is_locked"]:
            raise HTTPException(status_code=400, detail="Nhóm đã khóa, không thể tham gia.")
        
        cursor.execute("SELECT status FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        member = cursor.fetchone()
        if not member or member["status"] != "invited":
            raise HTTPException(status_code=400, detail="Không tìm thấy lời mời.")

        cursor.execute("SELECT COUNT(*) AS total FROM group_members WHERE group_id = %s AND status = 'member'", (group_id,))
        if cursor.fetchone()["total"] >= group["max_members"]:
            raise HTTPException(status_code=400, detail="Nhóm đã đầy.")
            
        cursor.execute("UPDATE group_members SET status='member' WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        create_notification(
            cursor,
            group['leader_id'],
            "Đã chấp nhận lời mời",
            f"Sinh viên {user_id} đã chấp nhận lời mời tham gia nhóm {group['name']}.",
            "invite_accepted",
            {"groupId": str(group_id), "userId": user_id}
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Đã tham gia nhóm"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/groups/{group_id}/reject-invite")
def reject_invite(group_id: int, user_id: str = Body(..., embed=True), reason: str = Body(..., embed=True)):
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        conn.start_transaction()
        cursor.execute("SELECT * FROM `groups` WHERE id = %s", (group_id,))
        group = cursor.fetchone()
        if not group:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm")
        
        cursor.execute("SELECT status FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        member = cursor.fetchone()
        if not member or member["status"] != "invited":
            raise HTTPException(status_code=400, detail="Không tìm thấy lời mời.")

        cursor.execute("DELETE FROM group_members WHERE group_id=%s AND user_id=%s", (group_id, user_id))
        create_notification(
            cursor,
            group['leader_id'],
            "Lời mời bị từ chối",
            f"Sinh viên {user_id} đã từ chối lời mời vào nhóm {group['name']}. Lý do: {reason}",
            "invite_rejected",
            {"groupId": str(group_id), "userId": user_id}
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {"message": "Đã từ chối lời mời"}
    except HTTPException:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise
    except Exception as e:
        if conn and conn.is_connected(): conn.rollback(); conn.close()
        raise HTTPException(status_code=400, detail=str(e))
"""

content = content.replace('@app.post("/groups/{group_id}/approve-member")', new_endpoints + '\n@app.post("/groups/{group_id}/approve-member")')

# Wait, `get_my_groups` in main.py also has a member fetch. Let's make sure it's updated.
# In get_my_groups:
# member_ids, pending_member_ids = get_group_members(cursor, row["id"])
# It was covered by step 4. But wait, `get_my_groups` uses a single query to fetch the groups, wait no:
# cursor.execute("""SELECT g.* FROM `groups` g JOIN group_members gm ON g.id = gm.group_id WHERE gm.user_id = %s ...""")

with open("backend/main.py", "w") as f:
    f.write(content)
