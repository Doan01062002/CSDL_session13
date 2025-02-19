-- 1,
use session13;

-- 2,
CREATE TABLE course_fees (
    course_id INT PRIMARY KEY,
    fee DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

CREATE TABLE student_wallets (
    student_id INT PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

-- 3,
INSERT INTO course_fees (course_id, fee) VALUES
(1, 100.00), -- Lập trình C: 100$
(2, 150.00); -- Cơ sở dữ liệu: 150$

INSERT INTO student_wallets (student_id, balance) VALUES
(1, 200.00), -- Nguyễn Văn An có 200$
(2, 50.00);  -- Trần Thị Ba chỉ có 50$

-- 4,
DELIMITER //
CREATE PROCEDURE RegisterCourse(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_balance DECIMAL(10,2);
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_available_seats INT;
    DECLARE v_status ENUM('active', 'graduated', 'suspended');
    
    START TRANSACTION;
    
    SELECT student_id INTO v_student_id FROM students WHERE student_name = p_student_name;
    SELECT status INTO v_status FROM student_status WHERE student_id = v_student_id;
    
    IF v_student_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (NULL, NULL, 'FAILED: Student does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student does not exist';
    END IF;
    
    IF v_status <> 'active' THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, NULL, 'FAILED: Student not eligible', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not eligible to enroll';
    END IF;
    
    SELECT course_id, available_seats INTO v_course_id, v_available_seats FROM courses WHERE course_name = p_course_name;
    
    IF v_course_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, NULL, 'FAILED: Course does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course does not exist';
    END IF;
    
    IF EXISTS (SELECT 1 FROM enrollments WHERE student_id = v_student_id AND course_id = v_course_id) THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: Already enrolled', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student already enrolled';
    END IF;
    
    IF v_available_seats <= 0 THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: No available seats', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available seats';
    END IF;
    
    SELECT balance INTO v_balance FROM student_wallets WHERE student_id = v_student_id;
    SELECT fee INTO v_fee FROM course_fees WHERE course_id = v_course_id;
    
    IF v_balance < v_fee THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: Insufficient balance', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
    
    INSERT INTO enrollments (student_id, course_id) VALUES (v_student_id, v_course_id);
    
    UPDATE student_wallets SET balance = balance - v_fee WHERE student_id = v_student_id;
    
    UPDATE courses SET available_seats = available_seats - 1 WHERE course_id = v_course_id;
    
    INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
    VALUES (v_student_id, v_course_id, 'REGISTERED', NOW());
    
    COMMIT;
END //
DELIMITER ;

-- 5,
CALL RegisterCourse('Nguyễn Văn An', 'Lập trình C');

-- 6,
SELECT * FROM student_wallets WHERE student_id = 1;
