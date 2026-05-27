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
    `identity` VARCHAR(20) UNIQUE,
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
    FOREIGN KEY (`lecturer_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Bảng Nhóm
-- LƯU Ý: 'groups' là từ khóa dành riêng trong MySQL 8.0+, bắt buộc phải dùng dấu `groups`
CREATE TABLE IF NOT EXISTS `groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `leader_id` VARCHAR(50),
    `max_members` INT DEFAULT 5,
    `topic_id` INT,
    `status` ENUM('pending_approval', 'approved', 'rejected') DEFAULT 'pending_approval',
    `is_locked` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`leader_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`topic_id`) REFERENCES `topics`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 4. Bảng Thành viên nhóm
CREATE TABLE IF NOT EXISTS `group_members` (
    `group_id` INT,
    `user_id` VARCHAR(50),
    `status` ENUM('pending', 'member') DEFAULT 'pending',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`group_id`, `user_id`),
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Chèn dữ liệu mẫu
REPLACE INTO `users` (`id`, `name`, `email`, `password`, `role`, `identity`) VALUES 
('admin', 'Quản trị viên', 'admin@gmail.com', '123', 'admin', 'ADMIN01'),
('gv01', 'Giảng viên 01', 'gv01@gmail.com', '123', 'lecturer', 'MSGV01'),
('sv01', 'Sinh viên 01', 'sv01@gmail.com', '123', 'student', 'MSSV01');
