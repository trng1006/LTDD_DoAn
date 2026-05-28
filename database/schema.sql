-- Cấu trúc Database MySQL cho Ứng dụng Đăng ký Đề tài
-- Sử dụng dấu backtick (`) để tránh lỗi từ khóa hệ thống (như 'groups')
CREATE DATABASE IF NOT EXISTS `student_registration`;
USE `student_registration`;

-- 1. Bảng Người dùng
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) UNIQUE NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('student', 'lecturer', 'admin') NOT NULL,
    `identity` VARCHAR(20) UNIQUE, -- MSSV cho sinh viên, MSGV cho giảng viên
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Bảng Đề tài
CREATE TABLE IF NOT EXISTS `topics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `lecturer_id` VARCHAR(50),
    `max_groups` INT DEFAULT 1,
    `current_groups` INT DEFAULT 0,
    `start_time` DATETIME,
    `end_time` DATETIME,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`lecturer_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Bảng Nhóm
CREATE TABLE IF NOT EXISTS `groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `leader_id` VARCHAR(50),
    `max_members` INT DEFAULT 5,
    `topic_id` INT,
    `status` ENUM('pending_approval', 'approved', 'rejected') DEFAULT 'pending_approval',
    `is_locked` BOOLEAN DEFAULT FALSE, -- Khóa nhóm khi đã đủ thành viên hoặc quá hạn
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`leader_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`topic_id`) REFERENCES `topics`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 4. Bảng Thành viên nhóm
CREATE TABLE IF NOT EXISTS `group_members` (
    `group_id` INT,
    `user_id` VARCHAR(50),
    `status` ENUM('pending', 'member') DEFAULT 'pending', -- pending: chờ trưởng nhóm duyệt
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`group_id`, `user_id`),
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- --- TRIGGERS ---

DELIMITER //

-- Trigger 0: Kiểm tra max_groups trước khi duyệt
CREATE TRIGGER before_group_update_check
BEFORE UPDATE ON `groups`
FOR EACH ROW
BEGIN
    DECLARE v_current INT;
    DECLARE v_max INT;
    
    -- Nếu chuyển sang trạng thái 'approved'
    IF OLD.status <> 'approved' AND NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        SELECT current_groups, max_groups INTO v_current, v_max 
        FROM topics WHERE id = NEW.topic_id;
        
        IF v_current >= v_max THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Đề tài này đã đủ số lượng nhóm đăng ký.';
        END IF;
    END IF;
END //

-- Trigger 1: Tăng current_groups khi nhóm được duyệt (approved)
CREATE TRIGGER after_group_update_approved
AFTER UPDATE ON `groups`
FOR EACH ROW
BEGIN
    -- Nếu chuyển từ trạng thái khác sang 'approved'
    IF OLD.status <> 'approved' AND NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        UPDATE `topics` 
        SET `current_groups` = `current_groups` + 1 
        WHERE `id` = NEW.topic_id;
    -- Nếu chuyển từ 'approved' sang trạng thái khác (rejected/pending)
    ELSEIF OLD.status = 'approved' AND NEW.status <> 'approved' AND OLD.topic_id IS NOT NULL THEN
        UPDATE `topics` 
        SET `current_groups` = `current_groups` - 1 
        WHERE `id` = OLD.topic_id;
    -- Nếu nhóm đã được duyệt nhưng thay đổi đề tài
    ELSEIF OLD.status = 'approved' AND NEW.status = 'approved' AND OLD.topic_id <> NEW.topic_id THEN
        IF OLD.topic_id IS NOT NULL THEN
            UPDATE `topics` SET `current_groups` = `current_groups` - 1 WHERE `id` = OLD.topic_id;
        END IF;
        IF NEW.topic_id IS NOT NULL THEN
            UPDATE `topics` SET `current_groups` = `current_groups` + 1 WHERE `id` = NEW.topic_id;
        END IF;
    END IF;
END //

-- Trigger 1.5: Handle insertion if status is already approved
CREATE TRIGGER after_group_insert_approved
AFTER INSERT ON `groups`
FOR EACH ROW
BEGIN
    IF NEW.status = 'approved' AND NEW.topic_id IS NOT NULL THEN
        UPDATE `topics` 
        SET `current_groups` = `current_groups` + 1 
        WHERE `id` = NEW.topic_id;
    END IF;
END //

-- Trigger 2: Giảm current_groups khi nhóm (đã approved) bị xóa
CREATE TRIGGER after_group_delete
AFTER DELETE ON `groups`
FOR EACH ROW
BEGIN
    IF OLD.status = 'approved' AND OLD.topic_id IS NOT NULL THEN
        UPDATE `topics` 
        SET `current_groups` = `current_groups` - 1 
        WHERE `id` = OLD.topic_id;
    END IF;
END //

DELIMITER ;

-- --- DỮ LIỆU MẪU ---

-- Chèn người dùng
REPLACE INTO `users` (`id`, `name`, `email`, `password`, `role`, `identity`) VALUES 
('admin', 'Quản trị viên Hệ thống', 'admin@gmail.com', 'admin123', 'admin', 'ADMIN01'),
('gv01', 'TS. Nguyễn Văn A', 'nva@fit.edu.vn', '123456', 'lecturer', 'MSGV01'),
('gv02', 'ThS. Trần Thị B', 'ttb@fit.edu.vn', '123456', 'lecturer', 'MSGV02'),
('sv01', 'Lê Văn Cường', 'cuonglv@student.edu.vn', '123456', 'student', 'MSSV2001'),
('sv02', 'Phạm Minh Hoàng', 'hoangpm@student.edu.vn', '123456', 'student', 'MSSV2002'),
('sv03', 'Nguyễn Thị Mai', 'maint@student.edu.vn', '123456', 'student', 'MSSV2003'),
('sv04', 'Trần Bảo Ngọc', 'ngoctb@student.edu.vn', '123456', 'student', 'MSSV2004'),
('sv05', 'Vũ Đức Anh', 'anhvd@student.edu.vn', '123456', 'student', 'MSSV2005');

-- Chèn đề tài
INSERT INTO `topics` (`id`, `title`, `description`, `lecturer_id`, `max_groups`) VALUES 
(1, 'Xây dựng Ứng dụng Quản lý Học tập', 'Phát triển ứng dụng di động hỗ trợ sinh viên quản lý lịch học và bài tập.', 'gv01', 3),
(2, 'Hệ thống Đăng ký Nhóm và Môn học', 'Xây dựng website hỗ trợ việc chia nhóm và chọn đề tài đồ án.', 'gv01', 2),
(3, 'Ứng dụng AI trong Chẩn đoán Hình ảnh', 'Sử dụng CNN để phân tích các hình ảnh X-quang.', 'gv02', 1);

-- Chèn nhóm (Nhóm 1 có 3 thành viên)
INSERT INTO `groups` (`id`, `name`, `description`, `leader_id`, `topic_id`, `status`) VALUES 
(1, 'Nhóm 01 - Mobile App', 'Thực hiện đề tài quản lý học tập.', 'sv01', 1, 'approved');

-- Chèn thành viên nhóm
INSERT INTO `group_members` (`group_id`, `user_id`, `status`) VALUES 
(1, 'sv01', 'member'),
(1, 'sv02', 'member'),
(1, 'sv03', 'member');
