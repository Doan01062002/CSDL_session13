use session13;

CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_name VARCHAR(100),
    available_seats INT NOT NULL
);

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
INSERT INTO students (student_name) VALUES ('Nguyễn Văn An'), ('Trần Thị Ba');

INSERT INTO courses (course_name, available_seats) VALUES 
('Lập trình C', 25), 
('Cơ sở dữ liệu', 22);


-- 2,
SET COMMIT = 0;

DELIMITER //

CREATE PROCEDURE EnrollStudent(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_available_seats INT;

    START TRANSACTION;

    SELECT student_id INTO v_student_id
    FROM students
    WHERE student_name = p_student_name;

    SELECT course_id, available_seats INTO v_course_id, v_available_seats
    FROM courses
    WHERE course_name = p_course_name;

    IF v_available_seats > 0 THEN
        INSERT INTO enrollments (student_id, course_id) 
        VALUES (v_student_id, v_course_id);

        UPDATE courses 
        SET available_seats = available_seats - 1
        WHERE course_id = v_course_id;

        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END //

DELIMITER ;

-- 3,
CALL EnrollStudent('Nguyễn Văn An', 'Lập trình C');
CALL EnrollStudent('Trần Thị Ba', 'Cơ sở dữ liệu');

SELECT * FROM enrollments;
SELECT * FROM courses;
