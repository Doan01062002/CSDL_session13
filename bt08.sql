-- 1,
use session13;

-- 2,
create table student_status(
	student_id int primary key auto_increment,
    status enum('active','graduated', 'suspended'),
    foreign key (student_id) references students(student_id)
);

-- 3,
INSERT INTO student_status (student_id, status) VALUES
(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký
(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký

-- 4,
DELIMITER //
CREATE PROCEDURE RegisterStudent (
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_status ENUM('active', 'graduated', 'suspended');
    DECLARE v_available_seats INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: Transaction Error', NOW());
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra sinh viên tồn tại
    SELECT student_id INTO v_student_id FROM students WHERE student_name = p_student_name;
    IF v_student_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (NULL, NULL, 'FAILED: Student does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student does not exist';
    END IF;
    
    -- Kiểm tra môn học tồn tại
    SELECT course_id, available_seats INTO v_course_id, v_available_seats FROM courses WHERE course_name = p_course_name;
    IF v_course_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, NULL, 'FAILED: Course does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course does not exist';
    END IF;
    
    -- Kiểm tra sinh viên đã đăng ký môn học chưa
    IF EXISTS (SELECT 1 FROM enrollments WHERE student_id = v_student_id AND course_id = v_course_id) THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: Already enrolled', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Already enrolled';
    END IF;
    
    -- Kiểm tra trạng thái của sinh viên
    SELECT status INTO v_status FROM student_status WHERE student_id = v_student_id;
    IF v_status IN ('graduated', 'suspended') THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: Student not eligible', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not eligible';
    END IF;
    
    -- Kiểm tra số chỗ trống của môn học
    IF v_available_seats > 0 THEN
        INSERT INTO enrollments (student_id, course_id) VALUES (v_student_id, v_course_id);
        UPDATE courses SET available_seats = available_seats - 1 WHERE course_id = v_course_id;
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'REGISTERED', NOW());
        COMMIT;
    ELSE
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (v_student_id, v_course_id, 'FAILED: No available seats', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available seats';
    END IF;
END //
DELIMITER ;

-- 5,
CALL RegisterStudent('Nguyễn Văn An', 'Lập trình C');
CALL RegisterStudent('Trần Thị Ba', 'Cơ sở dữ liệu');

-- 6,
SELECT * FROM enrollments;
SELECT * FROM courses;
SELECT * FROM enrollments_history;
