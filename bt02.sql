use session13;

-- 1,
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(50),
    price DECIMAL(10,2),
    stock INT NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    quantity INT NOT NULL,
    total_price DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO products (product_name, price, stock) VALUES
('Laptop Dell', 1500.00, 10),
('iPhone 13', 1200.00, 8),
('Samsung TV', 800.00, 5),
('AirPods Pro', 250.00, 20),
('MacBook Air', 1300.00, 7);

-- 2,
SET COMMIT = 0;

DELIMITER //
create procedure PlaceOrder( in p_product_id int, in p_quantity int )
begin
declare pro_stock int;
declare pro_price decimal(10,2);
declare total decimal(10,2);
select stock, price into pro_stock, pro_price from products where product_id = p_product_id;
if pro_stock < p_quantity then
	rollback;
else
	set total = pro_price * p_quantity;
    
    insert into orders(product_id, quantity, total_price)
		values(p_product_id, p_quantity, total);
	
    update products set stock = stock - p_quantity where product_id = p_product_id;
    
    commit;
end if;
end//
DELIMITER //

call PlaceOrder(1,2);

select * from orders;