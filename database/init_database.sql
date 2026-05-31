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
    `username` VARCHAR(50) UNIQUE NOT NULL, -- Added UNIQUE constraint and NOT NULL
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) UNIQUE NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('student', 'lecturer', 'admin') NOT NULL,
    `identity` VARCHAR(20) UNIQUE, -- MSSV cho sinh viên, MSGV cho giảng viên
    `current_semester_id` VARCHAR(50), -- Sinh viên đang ở học kỳ nào
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`current_semester_id`) REFERENCES `semesters`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Thêm cột is_active để quản lý trạng thái hoạt động của người dùng (mới)
ALTER TABLE `users` ADD COLUMN `is_active` BOOLEAN DEFAULT TRUE;
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

-- BẢNG TRUNG GIAN: Phân công Giảng dạy cho Giảng viên (Mới)
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

-- --- TRIGGERS ---

DELIMITER //

-- Trigger 0.1: Kiểm tra Role khi tạo/cập nhật Đề tài (lecturer_id phải có role 'lecturer')
CREATE TRIGGER before_topic_insert_role_check
BEFORE INSERT ON `topics`
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.lecturer_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.lecturer_id;
        IF v_role <> 'lecturer' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Giảng viên mới được phụ trách đề tài.';
        END IF;
    END IF;
END //

CREATE TRIGGER before_topic_update_role_check
BEFORE UPDATE ON `topics`
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.lecturer_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.lecturer_id;
        IF v_role <> 'lecturer' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Giảng viên mới được phụ trách đề tài.';
        END IF;
    END IF;
END //

-- Trigger 0.2: Kiểm tra Role khi tạo/cập nhật Nhóm (leader_id phải có role 'student')
CREATE TRIGGER before_group_insert_role_check
BEFORE INSERT ON `groups`
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.leader_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.leader_id;
        IF v_role <> 'student' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Sinh viên mới được làm trưởng nhóm.';
        END IF;
    END IF;
END //

CREATE TRIGGER before_group_update_role_check
BEFORE UPDATE ON `groups`
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(20);
    IF NEW.leader_id IS NOT NULL THEN
        SELECT role INTO v_role FROM users WHERE id = NEW.leader_id;
        IF v_role <> 'student' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ Sinh viên mới được làm trưởng nhóm.';
        END IF;
    END IF;
END //

-- Trigger 0.3: Kiểm tra max_members khi thêm thành viên vào group_members
CREATE TRIGGER before_group_member_insert_check
BEFORE INSERT ON `group_members`
FOR EACH ROW
BEGIN
    DECLARE v_current_members INT;
    DECLARE v_max_members INT;
    
    SELECT COUNT(*) INTO v_current_members FROM group_members WHERE group_id = NEW.group_id AND status = 'member';
    SELECT max_members INTO v_max_members FROM `groups` WHERE id = NEW.group_id;
    
    IF NEW.status = 'member' AND v_current_members >= v_max_members THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhóm đã đạt số lượng thành viên tối đa.';
    END IF;
END //

-- Trigger 0.4: Kiểm tra max_groups khi INSERT nhóm với status='approved'
CREATE TRIGGER before_group_insert_approved_check
BEFORE INSERT ON `groups`
FOR EACH ROW
BEGIN
    DECLARE v_current INT;
    DECLARE v_max INT;
    
    IF NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        SELECT current_groups, max_groups INTO v_current, v_max 
        FROM topics WHERE id = NEW.topic_id;
        
        IF v_current >= v_max THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đề tài này đã đủ số lượng nhóm đăng ký.';
        END IF;
    END IF;
END //

-- Trigger 0.5: Kiểm tra max_groups trước khi UPDATE sang 'approved'
CREATE TRIGGER before_group_update_check
BEFORE UPDATE ON `groups`
FOR EACH ROW
BEGIN
    DECLARE v_current INT;
    DECLARE v_max INT;
    
    IF OLD.status <> 'approved' AND NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        SELECT current_groups, max_groups INTO v_current, v_max 
        FROM topics WHERE id = NEW.topic_id;
        
        IF v_current >= v_max THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đề tài này đã đủ số lượng nhóm đăng ký.';
        END IF;
    END IF;
END //

-- Trigger 1: Tăng current_groups khi nhóm được duyệt (approved)
CREATE TRIGGER after_group_update_approved
AFTER UPDATE ON `groups`
FOR EACH ROW
BEGIN
    IF OLD.status <> 'approved' AND NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` + 1 WHERE `id` = NEW.topic_id;
    ELSEIF OLD.status = 'approved' AND NEW.status <> 'approved' AND OLD.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` - 1 WHERE `id` = OLD.topic_id;
    ELSEIF OLD.status = 'approved' AND NEW.status = 'approved' AND OLD.topic_id <> NEW.topic_id THEN
        IF OLD.topic_id IS NOT NULL THEN
            UPDATE `topics` SET `current_groups` = `current_groups` - 1 WHERE `id` = OLD.topic_id;
        END IF;
        IF NEW.topic_id IS NOT NULL THEN
            UPDATE `topics` SET `current_groups` = `current_groups` + 1 WHERE `id` = NEW.topic_id;
        END IF;
    END IF;
END //

-- Trigger 1.5: Tăng current_groups khi INSERT nhóm nếu status đã là approved
CREATE TRIGGER after_group_insert_approved
AFTER INSERT ON `groups`
FOR EACH ROW
BEGIN
    IF NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` + 1 WHERE `id` = NEW.topic_id;
    END IF;
END //

-- Trigger 2: Giảm current_groups khi nhóm (đã approved) bị xóa
CREATE TRIGGER after_group_delete
AFTER DELETE ON `groups`
FOR EACH ROW
BEGIN
    IF OLD.status = 'approved' AND OLD.topic_id IS NOT NULL THEN
        UPDATE `topics` SET `current_groups` = `current_groups` - 1 WHERE `id` = OLD.topic_id;
    END IF;
END //

DELIMITER ;

-- --- DỮ LIỆU MẪU ---

REPLACE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s6', 'Học kỳ 6', TRUE);

REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES 
('c1', 'Deep learning', '0101101956', 's6'),
('c2', 'Thực hành deep learning', '0101101957', 's6'),
('c3', 'Lập trình di động', '0101101969', 's6'),
('c4', 'Khai phá dữ liệu', '0101101970', 's6'),
('c5', 'Quản trị hệ thống mạng', '0101101973', 's6'),
('c6', 'Thực hành quản trị hệ thống mạng', '0101101974', 's6'),
('c7', 'Phân tích thiết kế hệ thống', '0101101976', 's6'),
('c8', 'Thực hành phân tích thiết kế hệ thống', '0101101977', 's6'),
('c9', 'Công nghệ Java', '0101101980', 's6');

REPLACE INTO `users` (`id`, `username`, `name`, `email`, `password`, `role`, `identity`, `current_semester_id`) VALUES 
('admin', 'admin', 'Quản trị viên Hệ thống', 'admin@gmail.com', 'admin123', 'admin', 'ADMIN01', NULL),
('gv01', 'gv01', 'TS. Nguyễn Văn A', 'nva@fit.edu.vn', '123456', 'lecturer', 'MSGV01', NULL),
('gv02', 'gv02', 'ThS. Trần Thị B', 'ttb@fit.edu.vn', '123456', 'lecturer', 'MSGV02', NULL),
('sv01', 'sv01', 'Lê Văn Cường', 'cuonglv@student.edu.vn', '123456', 'student', 'MSSV2001', 's6'),
('sv02', 'sv02', 'Phạm Minh Hoàng', 'hoangpm@student.edu.vn', '123456', 'student', 'MSSV2002', 's6'),
('sv03', 'sv03', 'Nguyễn Thị Mai', 'maint@student.edu.vn', '123456', 'student', 'MSSV2003', 's6'),
('sv04', 'sv04', 'Trần Bảo Ngọc', 'ngoctb@student.edu.vn', '123456', 'student', 'MSSV2004', 's6'),
('sv05', 'sv05', 'Vũ Đức Anh', 'anhvd@student.edu.vn', '123456', 'student', 'MSSV2005', 's6');

REPLACE INTO `student_courses` (`user_id`, `course_id`) VALUES 
('sv01', 'c1'), ('sv01', 'c3'), ('sv01', 'c7'),
('sv02', 'c1'), ('sv02', 'c2'), ('sv02', 'c3');

-- Chèn Phân công Giảng dạy
REPLACE INTO `lecturer_courses` (`user_id`, `course_id`) VALUES 
('gv01', 'c3'), ('gv01', 'c7'), ('gv01', 'c8'),
('gv02', 'c1'), ('gv02', 'c2');

INSERT INTO `topics` (`id`, `title`, `description`, `lecturer_id`, `course_id`, `max_groups`) VALUES 
(1, 'Xây dựng Ứng dụng Quản lý Học tập', 'Phát triển ứng dụng di động hỗ trợ sinh viên quản lý lịch học và bài tập.', 'gv01', 'c3', 3),
(2, 'Hệ thống Đăng ký Nhóm và Môn học', 'Xây dựng website hỗ trợ việc chia nhóm và chọn đề tài đồ án.', 'gv01', 'c7', 2),
(3, 'Ứng dụng AI trong Chẩn đoán Hình ảnh', 'Sử dụng CNN để phân tích các hình ảnh X-quang.', 'gv02', 'c1', 1);

INSERT INTO `groups` (`id`, `name`, `description`, `leader_id`, `course_id`, `topic_id`, `status`) VALUES 
(1, 'Nhóm 01 - Mobile App', 'Thực hiện đề tài quản lý học tập.', 'sv01', 'c3', 1, 'approved');

INSERT INTO `group_members` (`group_id`, `user_id`, `status`) VALUES 
(1, 'sv01', 'member'),
(1, 'sv02', 'member'),
(1, 'sv03', 'member');

# Các nhóm và thành viên khác có thể được thêm vào sau khi đề tài được duyệt và trong thời gian đăng ký.
-- Tạo bảng lưu cấu hình hệ thống
CREATE TABLE IF NOT EXISTS `system_settings` (
    `key_name` VARCHAR(50) PRIMARY KEY,
    `value` VARCHAR(255) NOT NULL,
    `description` VARCHAR(255),
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 7. Bang thong bao nguoi dung
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

-- Chèn dữ liệu cấu hình mặc định ban đầu (Seed data)
REPLACE INTO `system_settings` (`key_name`, `value`, `description`) VALUES 
('registration_start', '2026-05-01', 'Ngày bắt đầu đăng ký đề tài'),
('registration_end', '2026-06-30', 'Ngày kết thúc đăng ký đề tài'),
('min_members', '3', 'Số thành viên tối thiểu trong một nhóm'),
('max_members', '5', 'Số thành viên tối đa trong một nhóm');
-- Thêm 8 Học kỳ
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s1', 'Học kỳ 1', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s2', 'Học kỳ 2', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s3', 'Học kỳ 3', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s4', 'Học kỳ 4', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s5', 'Học kỳ 5', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s6', 'Học kỳ 6', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s7', 'Học kỳ 7', FALSE);
INSERT IGNORE INTO `semesters` (`id`, `name`, `is_active`) VALUES ('s8', 'Học kỳ 8', FALSE);

-- Thêm môn học
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001657', 'Giáo dục quốc phòng - an ninh 1', '0101001657', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101002298', 'Kinh tế chính trị Mác – Lênin', '0101002298', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101007641', 'Xác suất và thống kê trong sản xuất, công nghệ, kỹ thuật', '0101007641', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100651', 'Triết học Mác - Lênin', '0101100651', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100984', 'Đại số tuyến tính', '0101100984', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101922', 'Kỹ năng ứng dụng công nghệ thông tin', '0101101922', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101923', 'Nguyên lý ngôn ngữ lập trình', '0101101923', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101924', 'Thực hành Nguyên lý ngôn ngữ lập trình', '0101101924', 's1');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001662', 'Giáo dục quốc phòng - an ninh 2', '0101001662', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101003158', 'Mạng máy tính', '0101003158', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101005322', 'Thực hành mạng máy tính', '0101005322', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101006322', 'Tư tưởng Hồ Chí Minh', '0101006322', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100822', 'Anh văn 1', '0101100822', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101943', 'Cấu trúc dữ liệu và Giải thuật', '0101101943', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101961', 'Thực hành cấu trúc dữ liệu và giải thuật', '0101101961', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001697', 'Giáo dục thể chất 1 (Thể dục Thể hình)', '0101001697', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001703', 'Giáo dục thể chất 1 (Võ thuật)', '0101001703', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001704', 'Giáo dục thể chất 1 (Bóng đá)', '0101001704', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001705', 'Giáo dục thể chất 1 (Bóng chuyền)', '0101001705', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001706', 'Giáo dục thể chất 1 (Bơi lội)', '0101001706', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001707', 'Giáo dục thể chất 1 (Cầu lông)', '0101001707', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103085', 'Giáo dục thể chất 1 (Bóng rổ)', '0101103085', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103086', 'Giáo dục thể chất 1 (Pickleball)', '0101103086', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103087', 'Giáo dục thể chất 1 (Cờ vua)', '0101103087', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101003015', 'Logic học', '0101003015', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101003731', 'Phương pháp nghiên cứu khoa học', '0101003731', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101004030', 'Quy hoạch thực nghiệm', '0101004030', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100933', 'Giải tích', '0101100933', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100936', 'Đổi mới sáng tạo và khởi nghiệp', '0101100936', 's2');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101000476', 'Chủ nghĩa xã hội khoa học', '0101000476', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001669', 'Giáo dục quốc phòng - an ninh 3', '0101001669', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001677', 'Giáo dục quốc phòng - an ninh 4', '0101001677', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001742', 'Hệ điều hành', '0101001742', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101002289', 'Kiến trúc máy tính', '0101002289', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100823', 'Anh văn 2', '0101100823', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100986', 'Cấu trúc rời rạc', '0101100986', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001693', 'Giáo dục thể chất 2 (Bóng chuyền)', '0101001693', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001694', 'Giáo dục thể chất 2 (Bóng đá)', '0101001694', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001695', 'Giáo dục thể chất 2 (Cầu lông)', '0101001695', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001696', 'Giáo dục thể chất 2 (Thể dục Thể hình)', '0101001696', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001701', 'Giáo dục thể chất 2 (Võ thuật)', '0101001701', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101334', 'Giáo dục thể chất 2 (Bơi lội)', '0101101334', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103088', 'Giáo dục thể chất 2 (Bóng rổ)', '0101103088', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103089', 'Giáo dục thể chất 2 (Pickleball)', '0101103089', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103090', 'Giáo dục thể chất 2 (Cờ vua)', '0101103090', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001565', 'Đồ họa ứng dụng', '0101001565', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101005177', 'Thực hành kỹ thuật lập trình', '0101005177', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101007064', 'Kỹ thuật lập trình', '0101007064', 's3');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001625', 'Lịch sử Đảng Cộng sản Việt Nam', '0101001625', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101005281', 'Thực hành lập trình hướng đối tượng', '0101005281', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100824', 'Anh văn 3', '0101100824', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101954', 'Bảo mật máy tính', '0101101954', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101958', 'Hệ cơ sở dữ liệu', '0101101958', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101959', 'Thực hành Hệ cơ sở dữ liệu', '0101101959', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101962', 'Lập trình hướng đối tượng', '0101101962', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001702', 'Giáo dục thể chất 3 (Bóng đá)', '0101001702', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001718', 'Giáo dục thể chất 3 (Bóng chuyền)', '0101001718', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101001719', 'Giáo dục thể chất 3 (Cầu lông)', '0101001719', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100929', 'Giáo dục thể chất 3 (Bơi lội)', '0101100929', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100930', 'Giáo dục thể chất 3 (Thể dục Thể hình)', '0101100930', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101100931', 'Giáo dục thể chất 3 (Võ thuật)', '0101100931', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103091', 'Giáo dục thể chất 3 (Bóng rổ)', '0101103091', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103092', 'Giáo dục thể chất 3 (Pickleball)', '0101103092', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101103093', 'Giáo dục thể chất 3 (Cờ vua)', '0101103093', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101004725', 'Thiết kế web', '0101004725', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101955', 'Lập trình Python', '0101101955', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101967', 'Mã hóa và ứng dụng', '0101101967', 's4');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101002921', 'Lập trình web', '0101002921', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101006237', 'Trí tuệ nhân tạo', '0101006237', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101040', 'Thực hành Trí tuệ nhân tạo', '0101101040', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101963', 'Công nghệ phần mềm', '0101101963', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101968', 'Hệ quản trị cơ sở dữ liệu', '0101101968', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101964', 'Phân tích thiết kế thuật toán', '0101101964', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101965', 'Lập trình mạng', '0101101965', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101966', 'Ảo hóa và điện toán đám mây', '0101101966', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101007881', 'Công nghệ .NET', '0101007881', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101979', 'Xử lý ảnh', '0101101979', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101983', 'Bảo mật cơ sở dữ liệu', '0101101983', 's5');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101956', 'Deep learning', '0101101956', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101957', 'Thực hành deep learning', '0101101957', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101969', 'Lập trình di động', '0101101969', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101970', 'Khai phá dữ liệu', '0101101970', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101973', 'Quản trị hệ thống mạng', '0101101973', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101974', 'Thực hành quản trị hệ thống mạng', '0101101974', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101976', 'Phân tích thiết kế hệ thống', '0101101976', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101977', 'Thực hành phân tích thiết kế hệ thống', '0101101977', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101000002', 'Công Nghệ Java', '0101000002', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101980', 'Công nghệ phần mềm nâng cao', '0101101980', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101982', 'Thương mại điện tử', '0101101982', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101984', 'Kiểm định phần mềm', '0101101984', 's6');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101971', 'Nhập môn Big Data', '0101101971', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101972', 'Thực hành nhập môn Big data', '0101101972', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101975', 'Internet of Things', '0101101975', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102007', 'Thực tập nghề nghiệp', '0101102007', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102008', 'Khóa luận cử nhân', '0101102008', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101978', 'Lập trình mã nguồn mở', '0101101978', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101981', 'Dữ liệu NoSQL', '0101101981', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101985', 'An toàn mạng máy tính', '0101101985', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101986', 'Thực hành an toàn mạng máy tính', '0101101986', 's7');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101101015', 'Thực tập kỹ sư', '0101101015', 's8');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102009', 'Công tác kỹ sư', '0101102009', 's8');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102010', 'Chuyên đề công nghệ mới và chuyển đổi số', '0101102010', 's8');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102011', 'Học máy nâng cao', '0101102011', 's8');
REPLACE INTO `courses` (`id`, `name`, `code`, `semester_id`) VALUES ('c_0101102012', 'Khóa luận kỹ sư', '0101102012', 's8');

-- Seed lại mapping demo sau khi REPLACE courses theo mã môn để tránh mất liên kết do đổi id môn.
REPLACE INTO `student_courses` (`user_id`, `course_id`) VALUES
('sv01', 'c_0101101956'), ('sv01', 'c_0101101969'), ('sv01', 'c_0101101976'),
('sv02', 'c_0101101956'), ('sv02', 'c_0101101957'), ('sv02', 'c_0101101969');

REPLACE INTO `lecturer_courses` (`user_id`, `course_id`) VALUES
('gv01', 'c_0101101969'), ('gv01', 'c_0101101976'), ('gv01', 'c_0101101977'),
('gv02', 'c_0101101956'), ('gv02', 'c_0101101957');
