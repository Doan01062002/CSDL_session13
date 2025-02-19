-- 1,
use session13;

-- 2,
create table account(
	acc_id int primary key auto_increment,
    emp_id int,
    foreign key (emp_id) references employees(emp_id),
    bank_id int,
    foreign key (bank_id) references banks(bank_id),
    amount_added decimal(15,2),
    total_amount decimal(15,2)
);

-- 3,
INSERT INTO account (emp_id, bank_id, amount_added, total_amount) VALUES
(1, 1, 0.00, 12500.00),  
(2, 1, 0.00, 8900.00),   
(3, 1, 0.00, 10200.00),  
(4, 1, 0.00, 15000.00),  
(5, 1, 0.00, 7600.00);

-- 4,
DELIMITER //
CREATE PROCEDURE TransferSalaryAll()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_emp_id INT;
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_total_salary DECIMAL(15,2);
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_bank_id INT;
    DECLARE v_bank_status ENUM('active', 'error');
    
    -- Cursor để duyệt danh sách nhân viên
    DECLARE cur CURSOR FOR 
    SELECT emp_id, salary FROM employees;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        INSERT INTO transaction_log (log_message) VALUES ('FAILED: Transaction Rolled Back');
    END;
    
    START TRANSACTION;
    
    -- Lấy số dư quỹ công ty
    SELECT balance INTO v_balance FROM company_funds;
    
    -- Kiểm tra nếu không đủ tiền trả lương
    SELECT SUM(salary) INTO v_total_salary FROM employees;
    
    IF v_balance < v_total_salary THEN
        ROLLBACK;
        INSERT INTO transaction_log (log_message) VALUES ('FAILED: Insufficient Company Funds');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient Company Funds';
    END IF;
    
    -- Mở con trỏ và duyệt danh sách nhân viên
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_emp_id, v_salary;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Lấy trạng thái ngân hàng của nhân viên
        SELECT bank_id INTO v_bank_id FROM account WHERE emp_id = v_emp_id;
        SELECT status INTO v_bank_status FROM banks WHERE bank_id = v_bank_id;
        
        -- Kiểm tra trạng thái ngân hàng
        IF v_bank_status = 'error' THEN
            ROLLBACK;
            INSERT INTO transaction_log (log_message) VALUES ('FAILED: Bank Error');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bank Error';
        END IF;
        
        -- Cập nhật bảng company_funds (trừ lương)
        UPDATE company_funds SET balance = balance - v_salary;
        
        -- Thêm vào bảng payroll
        INSERT INTO payroll (emp_id, salary, pay_date) VALUES (v_emp_id, v_salary, CURDATE());
        
        -- Cập nhật tài khoản nhân viên
        UPDATE account 
        SET total_amount = total_amount + v_salary,
            amount_added = v_salary
        WHERE emp_id = v_emp_id;
        
    END LOOP;
    
    CLOSE cur;
    
    -- Ghi log thành công
    INSERT INTO transaction_log (log_message) VALUES (CONCAT('SUCCESS: Paid salary to ', (SELECT COUNT(*) FROM employees), ' employees'));
    
    COMMIT;
END //
DELIMITER ;

-- 5,
CALL TransferSalaryAll();

-- 6,
SELECT * FROM company_funds;
SELECT * FROM payroll;
SELECT * FROM account;
SELECT * FROM transaction_log;
