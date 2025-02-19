create database session13;

-- 1,
use session13;

-- 2,
create table banks(
	bank_id int primary key auto_increment,
    bank_name varchar(255) not null,
    status enum('active', 'error') not null default('active')
);

-- 3,
INSERT INTO banks (bank_id, bank_name, status) VALUES 
(1,'VietinBank', 'ACTIVE'),   
(2,'Sacombank', 'ERROR'),    
(3, 'Agribank', 'ACTIVE');

-- 4,
alter table company_funds 
add column bank_id int;

alter table company_funds
add constraint foreign key(bank_id) references company_funds(bank_id);

-- 5,
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;
INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);

-- 6,
drop trigger CheckBankStatus;
DELIMITER //
create trigger CheckBankStatus
before insert on payroll
for each row
begin
declare bank_status enum('active', 'error');

select status into bank_status from banks where bank_id = (select bank_id from company_funds limit 1);

if bank_status = 'error' then signal sqlstate '45000' set message_text = 'Ngân hàng đang gặp sự cố không thể trả lương';
end if;
end//
DELIMITER ;

-- 7,
drop procedure TransferSalary;
set autocommit = 0;
DELIMITER //
CREATE PROCEDURE TransferSalary(IN p_emp_id INT)
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_bank_status ENUM('active', 'error');
    DECLARE v_emp_exists INT;
    DECLARE exit handler FOR SQLEXCEPTION 
    BEGIN
		INSERT INTO transaction_log (log_message) VALUES ('Lỗi xảy ra trong quá trình chuyển lương!');
        ROLLBACK;
    END;

    START TRANSACTION;

    -- Kiểm tra nhân viên có tồn tại không
    SELECT COUNT(*), salary INTO v_emp_exists, v_salary FROM employees WHERE emp_id = p_emp_id;
    IF v_emp_exists = 0 THEN
        INSERT INTO transaction_log (log_message) VALUES ('Lỗi: Nhân viên không tồn tại!');
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- Lấy số dư quỹ công ty
    SELECT balance, bank_id INTO v_balance, @bank_id FROM company_funds LIMIT 1;

    -- Kiểm tra trạng thái ngân hàng
    SELECT status INTO v_bank_status FROM banks WHERE bank_id = @bank_id;
    IF v_bank_status = 'error' THEN
        INSERT INTO transaction_log (log_message) VALUES ('Lỗi: Ngân hàng gặp sự cố, không thể trả lương!');
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    --  Kiểm tra số dư quỹ có đủ trả lương không
    IF v_balance < v_salary THEN
        INSERT INTO transaction_log (log_message) VALUES ('Lỗi: Quỹ công ty không đủ tiền để trả lương!');
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- Trừ số tiền lương từ quỹ công ty
    UPDATE company_funds SET balance = balance - v_salary WHERE bank_id = @bank_id;

    -- Thêm bản ghi vào bảng payroll
    INSERT INTO payroll (emp_id, salary, pay_date) VALUES (p_emp_id, v_salary, CURDATE());

    -- Cập nhật ngày trả lương trong bảng employees
    UPDATE employees SET last_pay_date = CURDATE() WHERE emp_id = p_emp_id;

    -- Ghi log giao dịch thành công
    INSERT INTO transaction_log (log_message) 
    VALUES (CONCAT('Chuyển lương thành công cho nhân viên ID: ', p_emp_id, ', số tiền: ', v_salary));

    -- Commit giao dịch nếu mọi thứ thành công
    COMMIT;

    proc_end: END;
DELIMITER ;

-- 8,
call TransferSalary(1);
