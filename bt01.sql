create database session13;
use session13;

-- 1,
create table accounts(
	account_id int auto_increment primary key,
    account_name varchar(50),
    balance decimal(10,2)
);

-- 2,
INSERT INTO accounts (account_name, balance) VALUES 
('Nguyễn Văn An', 1000.00),
('Trần Thị Bảy', 500.00);

-- 3,
SET COMMIT = 0;

DELIMITER //
create procedure TransferMoney(in from_account int, in to_account int, in amount decimal(10,2))
begin
declare sender_balance decimal(10,2);
start transaction;
select balance into sender_balance from accounts where account_id = from_account;

if sender_balance >= amount then
	update accounts set balance = balance - amount where account_id = from_account;
    update accounts set balance = balance + amount where account_id = to_account;
    commit;
else
	rollback;
end if;
end//
DELIMITER //

-- 4,
CALL TransferMoney(1, 2, 200.00);

select * from accounts;