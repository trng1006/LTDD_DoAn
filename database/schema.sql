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
