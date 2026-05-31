# DeTai04_UngDungDangKyNhomVaDeTai

## Cách chạy

### 1. Chạy backend

Mở terminal trong thư mục `backend` rồi chạy:

```bash
cd backend
python main.py
```

Backend sẽ tự chạy FastAPI/Uvicorn tại:

```text
http://127.0.0.1:8000
```

Không cần chạy thêm `uvicorn main:app --reload`.

### 2. Chạy Flutter

Mở terminal tại thư mục gốc project rồi chạy:

```bash
flutter run
hoặc
flutter run -d <id của adb devices nếu chạy nhiều thiết bị song song>
```

Flutter tự dùng API trong `lib/core/services/api_service.dart`:

- Web/Desktop: `http://localhost:8000`
- Android Emulator: `http://10.0.2.2:8000`
- Có thể override bằng `--dart-define=API_BASE_URL=...` nếu cần chạy thiết bị thật.

File `lib/services/api_service.dart` hiện chỉ export lại service chính để tránh bị lệch code nếu import nhầm.

## Những phần đã hoàn thiện

### Luồng giảng viên

- Login `gv01` thành công.
- Màn quản lý đề tài chỉ hiển thị đề tài của chính giảng viên đang đăng nhập.
- Khi giảng viên thêm đề tài, dropdown môn học chỉ lấy các môn trong `lecturer_courses`.
- Backend chặn tạo/cập nhật đề tài nếu giảng viên chọn môn không được phân công dạy.
- Tạo đề tài xong reload lại danh sách và hiện ngay trong list.
- Màn duyệt nhóm đăng ký của giảng viên hiển thị nhóm `pending_approval`.
- Bấm `Duyệt` chuyển nhóm sang `approved`, `is_locked=true`.
- Bấm `Từ chối` chuyển nhóm sang `rejected`, `is_locked=false`.

### Luồng sinh viên/nhóm

- Màn tạo nhóm chỉ hiển thị môn sinh viên đang học trong `student_courses`.
- Chọn đề tài gọi đúng API `/groups/{id}/register-topic`.
- Đăng ký đề tài chuyển nhóm sang `pending_approval` và gửi thông báo cho giảng viên.
- Kiểm tra số lượng thành viên tối thiểu theo `group.minMembers`.

### Notification

- Backend tạo notification cho các sự kiện:
  - Sinh viên xin vào nhóm.
  - Trưởng nhóm duyệt/từ chối sinh viên.
  - Nhóm đăng ký đề tài.
  - Giảng viên duyệt/từ chối đề tài.
- Flutter có `NotificationProvider` polling mỗi 5 giây.
- Khi có thông báo mới sau lần load đầu, app hiện banner thả xuống ở đầu màn hình trong 1 giây.
(Lưu ý khi chạy song song nhiều thiết bị mới có)
- Nút `Thông báo` ngoài màn Home có badge số thông báo chưa đọc.
- Màn Thông báo hiển thị dữ liệu thật từ backend.
- Bấm 1 thông báo sẽ cập nhật `isRead=true`.
- Bấm đánh dấu tất cả đã đọc đưa unread count về `0`.

## File/thư mục đã thay đổi

### Backend

- `backend/main.py`
  - Thêm chạy trực tiếp bằng `python main.py`.
  - Thêm kiểm tra giảng viên phải dạy môn đó mới được tạo/sửa đề tài.
  - Hoàn thiện API tạo/sửa/xóa đề tài, đăng ký đề tài, duyệt/từ chối nhóm, notification.

- `backend/database.py`
  - Tự seed lại mapping demo cho `student_courses` và `lecturer_courses` nếu bảng mapping đang rỗng.
  - Đảm bảo `gv01`, `gv02`, `sv01`, `sv02` có môn học đúng để test.

- `database/init_database.sql`
  - Bổ sung seed mapping demo sau danh sách môn học mới:
    - `gv01`: Lập trình di động, Phân tích thiết kế hệ thống, Thực hành phân tích thiết kế hệ thống.
    - `gv02`: Deep learning, Thực hành deep learning.
    - `sv01`, `sv02`: các môn demo tương ứng.

### Flutter service/provider

- `lib/core/services/api_service.dart`
  - Là API service chính app đang dùng.
  - Thêm API duyệt/từ chối đề tài, lấy notification, mark read, mark all read.
  - Tự chọn base URL theo nền tảng chạy Flutter.

- `lib/services/api_service.dart`
  - Chuyển thành export tới `lib/core/services/api_service.dart` để tránh duplicate service.

- `lib/providers/auth_provider.dart`
  - Sau khi load user cache sẽ refresh lại user từ backend để không giữ danh sách môn cũ bị rỗng.

- `lib/providers/course_provider.dart`
  - Tự fetch môn/học kỳ từ backend.
  - Chọn môn mặc định hợp lệ theo danh sách môn của user.

- `lib/providers/topic_provider.dart`
  - Hỗ trợ fetch topic theo `lecturerId`.
  - Add/update topic trả kết quả thành công/thất bại và reload đúng danh sách.

- `lib/providers/group_provider.dart`
  - Hỗ trợ fetch group theo `lecturerId`, `status`, `topicId`.
  - Thêm logic register topic, approve topic, reject topic.

- `lib/providers/notification_provider.dart`
  - Polling realtime mỗi 5 giây.
  - Phát hiện notification mới theo ID và phát tín hiệu hiện banner 1 giây.
  - Hỗ trợ mark read và mark all read.

### Flutter screens

- `lib/main.dart`
  - Đăng ký `NotificationProvider`.
  - Tự start/stop polling notification theo user đăng nhập.
  - Thêm host hiển thị banner notification thả xuống 1 giây khi có thông báo mới.

- `lib/screens/home/home_screen.dart`
  - Thêm badge số thông báo chưa đọc trên nút `Thông báo` ngoài màn Home.

- `lib/screens/topic/topic_list_screen.dart`
  - Giảng viên chỉ thấy đề tài của mình.
  - Dropdown môn khi thêm đề tài chỉ gồm môn giảng viên dạy.
  - Lưu đề tài gọi backend thật và hiện kết quả.
  - Duyệt/từ chối nhóm từ chi tiết đề tài gọi API thật.

- `lib/screens/group/manage_group_screen.dart`
  - Sửa màn giảng viên duyệt nhóm đăng ký đề tài.
  - Hiển thị pending/approved/rejected.

- `lib/screens/group/create_group_screen.dart`
  - Dropdown môn học lấy đúng môn sinh viên đang học.

- `lib/screens/group/join_group_screen.dart`
  - Dropdown môn học lấy đúng môn sinh viên đang học.

- `lib/screens/group/group_detail_screen.dart`
  - Hiển thị trạng thái `rejected`.

- `lib/screens/topic/select_topic_screen.dart`
  - Thông báo đúng là đã gửi yêu cầu và chờ giảng viên duyệt.

- `lib/screens/notification/notification_screen.dart`
  - Thay màn dữ liệu mẫu bằng màn notification thật.

- `lib/models/notification_model.dart`
  - Bổ sung `type` và `data` để xử lý loại thông báo.

## Kịch bản đã test thành công

### Giảng viên

- Login `gv01`: thành công.
- Gọi danh sách topic theo `gv01`: chỉ trả topic của `gv01`.
- Tạo topic mới thuộc môn `gv01` dạy: thành công và xuất hiện trong list.
- Thử tạo topic cho môn `gv01` không dạy: backend trả `403`.
- Tạo nhóm sinh viên, đăng ký topic vừa tạo: nhóm chuyển `pending_approval`.
- `gv01` duyệt: nhóm chuyển `approved`, `is_locked=true`.
- Tạo nhóm khác, đăng ký topic, `gv01` từ chối: nhóm chuyển `rejected`, `is_locked=false`.

### Notification

- `sv02` xin vào nhóm của `sv01`: `sv01` nhận notification `join_request`.
- Khi notification mới được polling về: app hiện banner thả xuống trong 1 giây.
- Badge trên nút `Thông báo` ngoài Home hiển thị đúng số unread.
- `sv01` duyệt `sv02`: `sv02` nhận notification `join_approved`.
- Nhóm đăng ký đề tài: `gv01` nhận notification `topic_registration`.
- `gv01` duyệt đề tài: thành viên nhóm nhận notification `topic_approved`.
- `gv01` từ chối đề tài: thành viên nhóm nhận notification `topic_rejected`.
- Bấm 1 notification: `isRead=true`.
- Bấm đánh dấu tất cả đã đọc: unread về `0`.

## Kiểm tra kỹ thuật đã chạy

```bash
flutter analyze
python -m py_compile backend/main.py backend/database.py
```

Kết quả: không có lỗi.

`flutter test` chưa chạy được vì project hiện chưa có thư mục `test`.
