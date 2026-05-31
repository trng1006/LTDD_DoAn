-- Cấu trúc Database MySQL cho Ứng dụng Đăng ký Đề tài
-- Sử dụng dấu backtick (`) để tránh lỗi từ khóa hệ thống (như 'groups')
CREATE DATABASE IF NOT EXISTS `student_registration`;
USE `student_registration`;

-- 1. Bảng Học kỳ
CREATE TABLE IF NOT EXISTS `semesters` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `is_active` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Bảng Người dùng
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(50) PRIMARY KEY,
    `username` VARCHAR(50) UNIQUE NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) UNIQUE NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('student', 'lecturer', 'admin') NOT NULL,
    `identity` VARCHAR(20) UNIQUE, -- MSSV cho sinh viên, MSGV cho giảng viên
    `current_semester_id` VARCHAR(50), -- Sinh viên đang ở học kỳ nào
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`current_semester_id`) REFERENCES `semesters`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Bảng Môn học
CREATE TABLE IF NOT EXISTS `courses` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `code` VARCHAR(20) UNIQUE NOT NULL,
    `semester_id` VARCHAR(50),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`semester_id`) REFERENCES `semesters`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- BẢNG TRUNG GIAN: Đăng ký Môn học cho Sinh viên
CREATE TABLE IF NOT EXISTS `student_courses` (
    `user_id` VARCHAR(50),
    `course_id` VARCHAR(50),
    `enrolled_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `course_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- BẢNG TRUNG GIAN: Phân công Giảng dạy cho Giảng viên
CREATE TABLE IF NOT EXISTS `lecturer_courses` (
    `user_id` VARCHAR(50),
    `course_id` VARCHAR(50),
    `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `course_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Bảng Đề tài
CREATE TABLE IF NOT EXISTS `topics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `lecturer_id` VARCHAR(50),
    `course_id` VARCHAR(50),
    `max_groups` INT DEFAULT 1,
    `current_groups` INT DEFAULT 0,
    `start_time` DATETIME,
    `end_time` DATETIME,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`lecturer_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 5. Bảng Nhóm
CREATE TABLE IF NOT EXISTS `groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `leader_id` VARCHAR(50),
    `course_id` VARCHAR(50),
    `max_members` INT DEFAULT 5,
    `min_members` INT DEFAULT 2,
    `topic_id` INT,
    `status` ENUM('creating', 'pending_approval', 'approved', 'rejected') DEFAULT 'creating',
    `is_locked` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`leader_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`topic_id`) REFERENCES `topics`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6. Bảng Thành viên nhóm
CREATE TABLE IF NOT EXISTS `group_members` (
    `group_id` INT,
    `user_id` VARCHAR(50),
    `status` ENUM('pending', 'member') DEFAULT 'pending',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`group_id`, `user_id`),
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Bảng Thông báo
CREATE TABLE IF NOT EXISTS `notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` VARCHAR(50) DEFAULT 'general',
    `data` TEXT,
    `is_read` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_notifications_user_created` (`user_id`, `created_at`),
    INDEX `idx_notifications_user_read` (`user_id`, `is_read`)
) ENGINE=InnoDB;

-- 8. Cấu hình hệ thống
CREATE TABLE IF NOT EXISTS `system_settings` (
    `key_name` VARCHAR(50) PRIMARY KEY,
    `value` VARCHAR(255) NOT NULL,
    `description` VARCHAR(255),
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --- TRIGGERS ---

DELIMITER //

CREATE TRIGGER before_topic_insert_role_check BEFORE INSERT ON `topics` FOR EACH ROW BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.lecturer_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.lecturer_id;
        IF v_role <> 'lecturer' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Giảng viên mới được phụ trách đề tài.'; END IF;
    END IF;
END //

CREATE TRIGGER before_group_insert_role_check BEFORE INSERT ON `groups` FOR EACH ROW BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.leader_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.leader_id;
        IF v_role <> 'student' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Sinh viên mới được làm trưởng nhóm.'; END IF;
    END IF;
END //

CREATE TRIGGER before_group_member_insert_check BEFORE INSERT ON `group_members` FOR EACH ROW BEGIN
    DECLARE v_current_members INT;
    DECLARE v_max_members INT;
    SELECT COUNT(*) INTO v_current_members FROM group_members WHERE group_id = NEW.group_id AND status = 'member';
    SELECT max_members INTO v_max_members FROM `groups` WHERE id = NEW.group_id;
    IF NEW.status = 'member' AND v_current_members >= v_max_members THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhóm đã đạt số lượng thành viên tối đa.'; END IF;
END //

CREATE TRIGGER after_group_update_approved AFTER UPDATE ON `groups` FOR EACH ROW BEGIN
    IF OLD.status <> 'approved' AND NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` + 1 WHERE `id` = NEW.topic_id;
    ELSEIF OLD.status = 'approved' AND NEW.status <> 'approved' AND OLD.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` - 1 WHERE `id` = OLD.topic_id;
    END IF;
END //

DELIMITER ;

-- --- DỮ LIỆU MẪU ---

-- 1. Học kỳ
REPLACE INTO `semesters` (`id`, `name`, `is_active`) VALUES 
('s1', 'Học kỳ 1', FALSE), ('s2', 'Học kỳ 2', FALSE), ('s3', 'Học kỳ 3', FALSE), 
('s4', 'Học kỳ 4', FALSE), ('s5', 'Học kỳ 5', FALSE), ('s6', 'Học kỳ 6', TRUE), 
('s7', 'Học kỳ 7', FALSE), ('s8', 'Học kỳ 8', FALSE);

-- 2. Môn học
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES 
('c1', 'Deep learning', '0101101956', 's6'),
('c2', 'Thực hành deep learning', '0101101957', 's6'),
('c3', 'Lập trình di động', '0101101969', 's6'),
('c4', 'Khai phá dữ liệu', '0101101970', 's6'),
('c5', 'Quản trị hệ thống mạng', '0101101973', 's6'),
('c6', 'Thực hành quản trị hệ thống mạng', '0101101974', 's6'),
('c7', 'Phân tích thiết kế hệ thống', '0101101976', 's6'),
('c8', 'Thực hành phân tích thiết kế hệ thống', '0101101977', 's6'),
('c9', 'Công nghệ Java', '0101101980', 's6'),
('c_0101002921', 'Lập trình web', '0101002921', 's5'),
('c_0101006237', 'Trí tuệ nhân tạo', '0101006237', 's5'),
('c_0101101963', 'Công nghệ phần mềm', '0101101963', 's5'),
('c_0101101968', 'Hệ quản trị CSDL', '0101101968', 's5'),
('c_0101101966', 'Ảo hóa và Cloud', '0101101966', 's5'),
('c_0101101971', 'Nhập môn Big Data', '0101101971', 's7'),
('c_0101101975', 'Internet of Things', '0101101975', 's7'),
('c_0101101978', 'Lập trình mã nguồn mở', '0101101978', 's7'),
('c_0101101981', 'Dữ liệu NoSQL', '0101101981', 's7'),
('c_0101101985', 'An toàn mạng', '0101101985', 's7'),
('c_0101101984', 'Kiểm định phần mềm', '0101101984', 's6'),
('c_0101101979', 'Xử lý ảnh', '0101101979', 's5'),
('c_0101101955', 'Lập trình Python', '0101101955', 's4');

-- 3. Người dùng
REPLACE INTO `users` (`id`, `username`, `name`, `email`, `password`, `role`, `identity`, `current_semester_id`) VALUES 
('admin', 'admin', 'Quản trị viên', 'admin@gmail.com', 'admin123', 'admin', 'ADMIN01', NULL),
('gv01', 'gv01', 'TS. Nguyễn Văn A', 'nva@fit.edu.vn', '123456', 'lecturer', 'MSGV01', NULL),
('gv02', 'gv02', 'ThS. Trần Thị B', 'ttb@fit.edu.vn', '123456', 'lecturer', 'MSGV02', NULL),
('sv01', 'sv01', 'Lê Văn Cường', 'cuonglv@student.edu.vn', '123456', 'student', 'MSSV2001', 's6'),
('sv02', 'sv02', 'Phạm Minh Hoàng', 'hoangpm@student.edu.vn', '123456', 'student', 'MSSV2002', 's6'),
('sv03', 'sv03', 'Nguyễn Thị Mai', 'maint@student.edu.vn', '123456', 'student', 'MSSV2003', 's6'),
('sv04', 'sv04', 'Trần Bảo Ngọc', 'ngoctb@student.edu.vn', '123456', 'student', 'MSSV2004', 's6'),
('sv05', 'sv05', 'Vũ Đức Anh', 'anhvd@student.edu.vn', '123456', 'student', 'MSSV2005', 's6');

-- 4. Phân công giảng dạy
REPLACE INTO `lecturer_courses` (`user_id`, `course_id`) VALUES 
('gv01', 'c3'), ('gv01', 'c4'), ('gv01', 'c5'), ('gv01', 'c6'), ('gv01', 'c7'), ('gv01', 'c8'), ('gv01', 'c9'),
('gv02', 'c1'), ('gv02', 'c2'), ('gv02', 'c_0101101984'), ('gv02', 'c_0101006237'), ('gv02', 'c_0101101968'), ('gv02', 'c_0101101971'), ('gv02', 'c_0101101981'), ('gv02', 'c_0101101985'), ('gv02', 'c_0101101979');

-- 5. Đăng ký môn học cho Sinh viên (S6)
REPLACE INTO `student_courses` (`user_id`, `course_id`) VALUES 
('sv01', 'c1'), ('sv01', 'c2'), ('sv01', 'c3'), ('sv01', 'c4'), ('sv01', 'c5'), ('sv01', 'c6'), ('sv01', 'c7'), ('sv01', 'c8'), ('sv01', 'c9'), ('sv01', 'c_0101101984'),
('sv02', 'c1'), ('sv02', 'c2'), ('sv02', 'c3'), ('sv02', 'c4'), ('sv02', 'c5'), ('sv02', 'c6'), ('sv02', 'c7'), ('sv02', 'c8'), ('sv02', 'c9'), ('sv02', 'c_0101101984'),
('sv03', 'c1'), ('sv03', 'c2'), ('sv03', 'c3'), ('sv03', 'c4'), ('sv03', 'c5'), ('sv03', 'c6'), ('sv03', 'c7'), ('sv03', 'c8'), ('sv03', 'c9'), ('sv03', 'c_0101101984'),
('sv04', 'c1'), ('sv04', 'c2'), ('sv04', 'c3'), ('sv04', 'c4'), ('sv04', 'c5'), ('sv04', 'c6'), ('sv04', 'c7'), ('sv04', 'c8'), ('sv04', 'c9'), ('sv04', 'c_0101101984'),
('sv05', 'c1'), ('sv05', 'c2'), ('sv05', 'c3'), ('sv05', 'c4'), ('sv05', 'c5'), ('sv05', 'c6'), ('sv05', 'c7'), ('sv05', 'c8'), ('sv05', 'c9'), ('sv05', 'c_0101101984');

-- 6. Đề tài
REPLACE INTO `topics` (`id`, `title`, `description`, `lecturer_id`, `course_id`, `max_groups`) VALUES 
(1, 'Xây dựng Ứng dụng Quản lý Học tập', 'Phát triển ứng dụng di động hỗ trợ sinh viên quản lý lịch học và bài tập.', 'gv01', 'c3', 3),
(2, 'Hệ thống Đăng ký Nhóm và Môn học', 'Xây dựng website hỗ trợ việc chia nhóm và chọn đề tài đồ án.', 'gv01', 'c7', 2),
(3, 'Ứng dụng AI trong Chẩn đoán Hình ảnh', 'Sử dụng CNN để phân tích các hình ảnh X-quang.', 'gv02', 'c1', 1),
(4, 'Ứng dụng đặt món ăn trực tuyến', 'Phát triển ứng dụng di động cho phép người dùng đặt món và thanh toán trực tuyến.', 'gv01', 'c3', 2),
(5, 'Hệ thống quản lý thư viện thông minh', 'Phân tích và thiết kế hệ thống quản lý mượn trả sách tự động.', 'gv01', 'c7', 2),
(6, 'Nhận diện chữ viết tay bằng CNN', 'Sử dụng mạng nơ-ron tích chập để nhận diện chữ số viết tay.', 'gv02', 'c1', 1),
(7, 'Phân loại rác thải bằng Computer Vision', 'Xây dựng mô hình phân loại các loại rác thải tái chế.', 'gv02', 'c2', 1),
(8, 'Dự báo giá chứng khoán bằng LSTM', 'Ứng dụng mạng LSTM để dự báo xu hướng giá chứng khoán.', 'gv02', 'c1', 1),
(9, 'Xây dựng website bán hàng điện tử', 'Hệ thống website hỗ trợ thanh toán online.', 'gv01', 'c_0101002921', 3),
(10, 'Ứng dụng Chatbot hỗ trợ tuyển sinh', 'Sử dụng NLP để xây dựng bot trả lời tự động.', 'gv02', 'c_0101006237', 2),
(11, 'Hệ thống quản lý kho hàng', 'Phân tích quy trình nhập xuất kho.', 'gv01', 'c_0101101963', 2),
(12, 'Tối ưu hóa truy vấn SQL Server', 'Nghiên cứu Index và hiệu năng câu lệnh SQL.', 'gv02', 'c_0101101968', 1),
(13, 'Triển khai Web trên Docker', 'Sử dụng Container để triển khai hệ thống Web.', 'gv01', 'c_0101101966', 2),
(14, 'Phát hiện khuôn mặt bằng Deep Learning', 'Ứng dụng OpenCV và mạng nơ-ron.', 'gv02', 'c1', 1),
(15, 'Ứng dụng theo dõi sức khỏe', 'App di động tích hợp cảm biến nhịp tim.', 'gv01', 'c3', 3),
(16, 'Phân tích hành vi mua sắm', 'Sử dụng kỹ thuật Clustering để phân nhóm khách hàng.', 'gv02', 'c4', 2),
(17, 'Giám sát mạng Zabbix', 'Theo dõi tài nguyên server và cảnh báo.', 'gv01', 'c5', 1),
(18, 'Thiết kế hệ thống rạp chiếu phim', 'Xây dựng sơ đồ quy trình quản lý vé.', 'gv01', 'c7', 2),
(19, 'Dữ liệu lớn trên Hadoop', 'Xử lý các tệp dữ liệu log khổng lồ.', 'gv02', 'c_0101101971', 1),
(20, 'Nhà thông minh qua MQTT', 'Điều khiển thiết bị điện gia dụng qua ứng dụng.', 'gv01', 'c_0101101975', 2),
(21, 'Phát triển ứng dụng React Native', 'Xây dựng app đa nền tảng.', 'gv01', 'c_0101101978', 3),
(22, 'Quản lý log với MongoDB', 'Ứng dụng NoSQL để lưu trữ dữ liệu log.', 'gv02', 'c_0101101981', 2),
(23, 'Hệ thống xâm nhập Snort', 'Triển khai IDS để bảo vệ hạ tầng mạng.', 'gv02', 'c_0101101985', 1),
(24, 'Ứng dụng AR hỗ trợ học tập', 'Sử dụng thực tế ảo tăng cường.', 'gv01', 'c3', 2),
(25, 'Nhận diện biển số xe', 'Ứng dụng xử lý ảnh và YOLO.', 'gv02', 'c_0101101979', 1),
(26, 'Phát triển Game 2D với Flutter', 'Xây dựng game sử dụng Flame engine.', 'gv01', 'c3', 3),
(27, 'Phân tích cảm xúc văn bản', 'Sử dụng LSTM và BERT.', 'gv02', 'c_0101006237', 2),
(28, 'Bảo mật WiFi doanh nghiệp', 'Nghiên cứu các giao thức WPA3.', 'gv01', 'c5', 1),
(29, 'Quản lý khách sạn (Java)', 'Dùng Java Swing và MySQL.', 'gv01', 'c9', 2),
(30, 'Tự động báo cáo Python', 'Xây dựng công cụ tự động hóa dữ liệu.', 'gv02', 'c_0101101955', 3),
(31, 'Framework kiểm thử Selenium', 'Kiểm thử website thương mại điện tử.', 'gv01', 'c_0101101984', 2),
(32, 'Nhận diện biển báo giao thông', 'Sử dụng máy học để nhận diện biển báo.', 'gv02', 'c_0101006237', 1),
(33, 'VPN site-to-site', 'Thiết lập kết nối an toàn IPsec.', 'gv01', 'c5', 1);

-- 7. Nhóm
REPLACE INTO `groups` (`id`, `name`, `description`, `leader_id`, `course_id`, `topic_id`, `status`) VALUES 
(1, 'Nhóm 01 - Mobile App', 'Thực hiện đề tài quản lý học tập.', 'sv01', 'c3', 1, 'approved');

REPLACE INTO `group_members` (`group_id`, `user_id`, `status`) VALUES (1, 'sv01', 'member'), (1, 'sv02', 'member'), (1, 'sv03', 'member');

-- 8. Cấu hình
REPLACE INTO `system_settings` (`key_name`, `value`, `description`) VALUES 
('registration_start', '2026-05-01', 'Ngày bắt đầu đăng ký'), ('registration_end', '2026-06-30', 'Ngày kết thúc đăng ký'),
('min_members', '3', 'Số thành viên tối thiểu'), ('max_members', '5', 'Số thành viên tối đa');
