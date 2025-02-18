-- 1,
use session13;

CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL -- Số dư quỹ công ty
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,   -- Tên nhân viên
    salary DECIMAL(10,2) NOT NULL    -- Lương nhân viên
);

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,                      -- ID nhân viên (FK)
    salary DECIMAL(10,2) NOT NULL,   -- Lương được nhận
    pay_date DATE NOT NULL,          -- Ngày nhận lương
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);


INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);

-- 2,
CREATE TABLE transaction_log(
	log_id int primary key auto_increment,
    log_message text not null,
    log_time timestamp default (current_timestamp())
);

-- 3,
ALTER TABLE transaction_log 
ADD COLUMN last_pay_date DATE DEFAULT(now());

-- 4,
SET autocommit = 0;

DELIMITER //

CREATE PROCEDURE transferMoney (
    IN employeeId INT,
    IN fundId INT
)
BEGIN
    DECLARE com_balance DECIMAL(15,2);
    DECLARE emp_salary DECIMAL(10,2);
    DECLARE today_date DATE;
    
    SET today_date = CURDATE();

    START TRANSACTION;

    IF (SELECT COUNT(emp_id) FROM employees WHERE emp_id = employeeId) = 0 
        OR (SELECT COUNT(fund_id) FROM company_funds WHERE fund_id = fundId) = 0 
    THEN
        INSERT INTO transaction_log(log_message)
        VALUES ('ID nhân viên hoặc ID quỹ công ty không tồn tại');
        ROLLBACK;
    ELSE
        SELECT balance INTO com_balance FROM company_funds WHERE fund_id = fundId;
        
        SELECT salary INTO emp_salary FROM employees WHERE emp_id = employeeId;

        IF com_balance < emp_salary THEN
            INSERT INTO transaction_log(log_message)
            VALUES ('Số dư tài khoản công ty không đủ để trả lương');
            ROLLBACK;
        ELSE 
            UPDATE company_funds
            SET balance = balance - emp_salary
            WHERE fund_id = fundId;

            INSERT INTO payroll (emp_id, salary, pay_date)
            VALUES (employeeId, emp_salary, today_date);

            INSERT INTO transaction_log(log_message, last_pay_date)
            VALUES ('Chuyển khoản thành công', today_date);

            COMMIT;
        END IF;
    END IF;
END //
DELIMITER ;

CALL transferMoney(1,1);

SELECT * FROM company_funds;
SELECT * FROM payroll;
SELECT * FROM transaction_log;
