CREATE DATABASE IPS;
USE IPS;

SHOW VARIABLES LIKE 'secure_file_priv';

CREATE TABLE branch (
	branch_id VARCHAR(4) PRIMARY KEY,
    province TEXT,
    city TEXT,
    area TEXT
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/branch.csv'
INTO TABLE branch
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM branch;

CREATE TABLE staff (
	staff_id VARCHAR(5) PRIMARY KEY,
    full_name_staff TEXT,
    gender_staff TEXT,
    branch_id VARCHAR(4),
    position TEXT,
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/staff.csv'
INTO TABLE staff
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM staff;
INSERT INTO staff (staff_id, full_name_staff, gender_staff, branch_id, position)
VALUES ('S0000', NULL, NULL, NULL, NULL);

CREATE TABLE subs_package (
	plan_id VARCHAR(4) PRIMARY KEY,
    plan_name TEXT,
    type TEXT,
    category TEXT,
    speed_mbps INT,
    monthly_price_idr INT,
    downpayment_idr INT,
    duration_days INT,
    total_installment INT,
    device_recommendation INT,
    existing_customer_only TEXT,
    min_completed_contracts INT
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/subs_package.csv'
INTO TABLE subs_package
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM subs_package;

CREATE TABLE customer (
	customer_id VARCHAR(10) PRIMARY KEY,
    customer_type TEXT,
    full_name_customer TEXT,
    gender_customer TEXT,
    yob_customer TEXT,
    work_customer TEXT,
    business_field TEXT,
    branch_id VARCHAR (4),
    customer_acquisition TEXT,
    staff_id VARCHAR (5),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) 
    );
   
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customer
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM customer;
drop table transaction;
CREATE TABLE transaction (
	transaction_id VARCHAR(9) PRIMARY KEY,
    customer_id VARCHAR(10),
    plan_id VARCHAR(4),
    plan_id2 TEXT,
    date TEXT,
    payment_type TEXT,
    payment_method TEXT,
    installment INT,
    total_payment INT,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (plan_id) REFERENCES subs_package(plan_id) 
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transaction.csv'
INTO TABLE transaction
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE transaction
MODIFY date DATE;
    
SELECT * FROM transaction;

SELECT * FROM staff
WHERE position = 'Branch Manager';

SELECT payment_type, SUM(total_payment) AS total_revenue
FROM transaction
GROUP BY payment_type;

SELECT payment_type, SUM(total_payment) AS total_revenue
FROM transaction
WHERE date BETWEEN '2025-01-01' AND '2025-02-01'
GROUP BY payment_type;

ALTER TABLE transaction
ADD COLUMN month VARCHAR(7);

UPDATE transaction
SET month = DATE_FORMAT(date, '%Y-%m');

CREATE TABLE monthly_package_purchased AS
SELECT plan_id, month, COUNT(installment) AS total_package_purchased
FROM transaction
WHERE installment = 1
GROUP BY month, plan_id
ORDER BY month;

SELECT m.month, t.plan_id, m.max_purchase
FROM monthly_package_purchased t
JOIN (
    SELECT month, MAX(total_package_purchased) AS max_purchase
    FROM monthly_package_purchased
    GROUP BY month
) m
ON t.month = m.month
AND t.total_package_purchased = m.max_purchase;

ALTER TABLE customer
ADD COLUMN first_transaction DATE;

UPDATE customer c
SET first_transaction = (
	SELECT MIN(t.date)
    FROM transaction t
    WHERE t.customer_id = c.customer_id
);

ALTER TABLE customer
ADD COLUMN first_month_transaction VARCHAR(7);

UPDATE customer
SET first_month_transaction = DATE_FORMAT(first_transaction, '%Y-%m');

CREATE TABLE monthly_new_customers AS
SELECT staff_id, COUNT(customer_id) AS total_new_customers, first_month_transaction
FROM customer
GROUP BY staff_id, first_month_transaction
ORDER BY first_month_transaction;

DELETE FROM monthly_new_customers
WHERE staff_id = 'S0000';

SELECT m.first_month_transaction, t.staff_id, m.max_total_newcust
FROM monthly_new_customers t
JOIN (
	SELECT first_month_transaction, MAX(total_new_customers) AS max_total_newcust
    FROM monthly_new_customers t
    GROUP BY first_month_transaction
) m
ON t.first_month_transaction = m.first_month_transaction
AND t.total_new_customers = m.max_total_newcust;