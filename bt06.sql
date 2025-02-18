-- 1,
use session13;

-- 2,

CREATE TABLE enrollments_history(
	history_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    course_id INT,
	FOREIGN KEY (course_id) REFERENCES courses(course_id),
    action VARCHAR(50),
    timestamp DATETIME
);

-- 3,
SET COMMIT = 0;
DELIMITER //

CREATE PROCEDURE register_course(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_available_seats INT;
    DECLARE v_already_enrolled INT;

    START TRANSACTION;

    SELECT student_id INTO v_student_id FROM students WHERE student_name = p_student_name;
    
    SELECT course_id, available_seats INTO v_course_id, v_available_seats 
    FROM courses WHERE course_name = p_course_name;

    IF v_student_id IS NULL OR v_course_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
        VALUES (NULL, NULL, 'Đăng ký thất bại - Sinh viên hoặc môn học không tồn tại', NOW());
        ROLLBACK;
    ELSE
        SELECT COUNT(*) INTO v_already_enrolled 
        FROM enrollments 
        WHERE student_id = v_student_id AND course_id = v_course_id;

        IF v_already_enrolled > 0 THEN
            INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
            VALUES (v_student_id, v_course_id, 'Đăng ký thất bại - Đã đăng ký trước đó', NOW());
            ROLLBACK;
        ELSE
            IF v_available_seats > 0 THEN
                INSERT INTO enrollments (student_id, course_id) 
                VALUES (v_student_id, v_course_id);
                
                UPDATE courses 
                SET available_seats = available_seats - 1 
                WHERE course_id = v_course_id;

                INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
                VALUES (v_student_id, v_course_id, 'Đăng ký thành công', NOW());

                COMMIT;
            ELSE
                INSERT INTO enrollments_history (student_id, course_id, action, timestamp)
                VALUES (v_student_id, v_course_id, 'Đăng ký thất bại - Hết chỗ', NOW());
                ROLLBACK;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- 4,
CALL register_course('Nguyễn Văn An', 'Lập trình C');
CALL register_course('Trần Thị Ba', 'Cơ sở dữ liệu');

-- 5,
SELECT * FROM enrollments;
SELECT * FROM courses;
SELECT * FROM enrollments_history;

