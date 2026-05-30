-- Dữ liệu thật bổ sung cho 2 lớp: c3 (Lập trình di động) & c7 (Phân tích thiết kế hệ thống)
USE `student_registration`;

-- Đảm bảo sinh viên đăng ký đủ 2 lớp để thử chức năng đổi lớp
REPLACE INTO `student_courses` (`user_id`, `course_id`) VALUES
('sv01','c3'), ('sv01','c7'),
('sv02','c3'), ('sv02','c7'),
('sv03','c3'), ('sv03','c7'),
('sv04','c3'), ('sv04','c7'),
('sv05','c3'), ('sv05','c7');

-- Đề tài cho lớp c3 - Lập trình di động (giảng viên gv01 phụ trách)
INSERT INTO `topics` (`title`, `description`, `lecturer_id`, `course_id`, `max_groups`) VALUES
('Hệ thống quản lý bán hàng', 'Quản lý sản phẩm, đơn hàng và doanh thu.', 'gv01', 'c3', 3),
('Hệ thống quản lý phòng khám', 'Quản lý bệnh nhân, lịch hẹn và hồ sơ.', 'gv01', 'c3', 3),
('Hệ thống quản lý nhà trọ', 'Quản lý phòng, hợp đồng và thanh toán.', 'gv01', 'c3', 2);

-- Đề tài cho lớp c7 - Phân tích thiết kế hệ thống (giảng viên gv01 phụ trách)
INSERT INTO `topics` (`title`, `description`, `lecturer_id`, `course_id`, `max_groups`) VALUES
('Hệ thống đặt vé máy bay', 'Tìm kiếm chuyến bay và đặt vé trực tuyến.', 'gv01', 'c7', 3),
('Hệ thống quản lý thư viện', 'Quản lý sách, bạn đọc và mượn trả.', 'gv01', 'c7', 3),
('Hệ thống quản lý sinh viên', 'Quản lý thông tin, điểm số và học phần.', 'gv01', 'c7', 2);
