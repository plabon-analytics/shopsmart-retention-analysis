-- ============================================================
--  ShopSmart Analytics Database
--  Practice database for SQL Mastery (Levels 1-10)
--  Run this entire file in MySQL Workbench
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS shopsmart;
CREATE DATABASE shopsmart;
USE shopsmart;

-- ============================================================
--  TABLE 1: customers
-- ============================================================
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY AUTO_INCREMENT,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    city          VARCHAR(80),
    country       VARCHAR(50) DEFAULT 'India',
    segment       VARCHAR(20),   -- 'Premium', 'Standard', 'Budget'
    signup_date   DATE NOT NULL
);

-- ============================================================
--  TABLE 2: products
-- ============================================================
CREATE TABLE products (
    product_id    INT PRIMARY KEY AUTO_INCREMENT,
    product_name  VARCHAR(150) NOT NULL,
    category      VARCHAR(60),
    sub_category  VARCHAR(60),
    price         DECIMAL(10,2) NOT NULL,
    cost          DECIMAL(10,2) NOT NULL
);

-- ============================================================
--  TABLE 3: orders
-- ============================================================
CREATE TABLE orders (
    order_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    order_date      DATE NOT NULL,
    status          VARCHAR(20),  -- 'Delivered', 'Cancelled', 'Processing', 'Returned'
    payment_method  VARCHAR(30),  -- 'UPI', 'Credit Card', 'Debit Card', 'COD', 'Net Banking'
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================================
--  TABLE 4: order_items
-- ============================================================
CREATE TABLE order_items (
    item_id       INT PRIMARY KEY AUTO_INCREMENT,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL DEFAULT 1,
    unit_price    DECIMAL(10,2) NOT NULL,
    discount      DECIMAL(5,2) DEFAULT 0.00,  -- percentage e.g. 10.00 = 10%
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================
--  TABLE 5: returns
-- ============================================================
CREATE TABLE returns (
    return_id    INT PRIMARY KEY AUTO_INCREMENT,
    order_id     INT NOT NULL,
    product_id   INT NOT NULL,
    return_date  DATE NOT NULL,
    reason       VARCHAR(100),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================
--  TABLE 6: marketing_campaigns
-- ============================================================
CREATE TABLE marketing_campaigns (
    campaign_id        INT PRIMARY KEY AUTO_INCREMENT,
    campaign_name      VARCHAR(150) NOT NULL,
    channel            VARCHAR(40),  -- 'Email', 'Instagram', 'Google Ads', 'SMS', 'YouTube'
    start_date         DATE,
    end_date           DATE,
    budget_spent       DECIMAL(12,2),
    customers_reached  INT
);


-- ============================================================
--  SAMPLE DATA: customers (50 customers)
-- ============================================================
INSERT INTO customers (full_name, email, city, country, segment, signup_date) VALUES
('Aarav Sharma',       'aarav.sharma@gmail.com',       'Mumbai',      'India', 'Premium',  '2021-03-15'),
('Priya Patel',        'priya.patel@yahoo.com',         'Ahmedabad',   'India', 'Standard', '2021-04-22'),
('Rohan Mehta',        'rohan.mehta@gmail.com',         'Delhi',       'India', 'Premium',  '2021-05-10'),
('Sneha Iyer',         'sneha.iyer@outlook.com',        'Chennai',     'India', 'Budget',   '2021-06-03'),
('Vikram Singh',       'vikram.singh@gmail.com',        'Jaipur',      'India', 'Standard', '2021-07-18'),
('Ananya Nair',        'ananya.nair@gmail.com',         'Kochi',       'India', 'Premium',  '2021-08-09'),
('Karan Gupta',        'karan.gupta@hotmail.com',       'Pune',        'India', 'Budget',   '2021-09-25'),
('Pooja Reddy',        'pooja.reddy@gmail.com',         'Hyderabad',   'India', 'Standard', '2021-10-14'),
('Arjun Bose',         'arjun.bose@gmail.com',          'Kolkata',     'India', 'Premium',  '2021-11-30'),
('Meera Joshi',        'meera.joshi@yahoo.com',         'Nagpur',      'India', 'Budget',   '2021-12-07'),
('Rahul Verma',        'rahul.verma@gmail.com',         'Lucknow',     'India', 'Standard', '2022-01-19'),
('Divya Krishnan',     'divya.krishnan@gmail.com',      'Bengaluru',   'India', 'Premium',  '2022-02-28'),
('Amit Tiwari',        'amit.tiwari@outlook.com',       'Bhopal',      'India', 'Budget',   '2022-03-11'),
('Sonal Desai',        'sonal.desai@gmail.com',         'Surat',       'India', 'Standard', '2022-04-05'),
('Nikhil Rao',         'nikhil.rao@gmail.com',          'Bengaluru',   'India', 'Premium',  '2022-05-20'),
('Kavya Menon',        'kavya.menon@yahoo.com',         'Kochi',       'India', 'Budget',   '2022-06-17'),
('Shubham Mishra',     'shubham.mishra@gmail.com',      'Varanasi',    'India', 'Standard', '2022-07-03'),
('Ritika Agarwal',     'ritika.agarwal@gmail.com',      'Delhi',       'India', 'Premium',  '2022-08-22'),
('Deepak Nath',        'deepak.nath@hotmail.com',       'Guwahati',    'India', 'Budget',   '2022-09-14'),
('Ishita Ghosh',       'ishita.ghosh@gmail.com',        'Kolkata',     'India', 'Standard', '2022-10-01'),
('Manish Pandey',      'manish.pandey@gmail.com',       'Patna',       'India', 'Budget',   '2022-11-08'),
('Shruti Kapoor',      'shruti.kapoor@gmail.com',       'Delhi',       'India', 'Premium',  '2022-12-15'),
('Tarun Saxena',       'tarun.saxena@yahoo.com',        'Kanpur',      'India', 'Standard', '2023-01-27'),
('Preethi Subramaniam','preethi.subram@gmail.com',      'Chennai',     'India', 'Premium',  '2023-02-09'),
('Gaurav Malhotra',    'gaurav.malhotra@gmail.com',     'Chandigarh',  'India', 'Standard', '2023-03-21'),
('Neha Kulkarni',      'neha.kulkarni@outlook.com',     'Pune',        'India', 'Budget',   '2023-04-16'),
('Varun Bajaj',        'varun.bajaj@gmail.com',         'Ludhiana',    'India', 'Premium',  '2023-05-04'),
('Asha Pillai',        'asha.pillai@gmail.com',         'Thiruvananthapuram', 'India', 'Standard', '2023-06-12'),
('Siddharth Jain',     'siddharth.jain@gmail.com',      'Indore',      'India', 'Budget',   '2023-07-29'),
('Lakshmi Venkat',     'lakshmi.venkat@yahoo.com',      'Hyderabad',   'India', 'Premium',  '2023-08-18'),
('Ravi Shankar',       'ravi.shankar@gmail.com',        'Mumbai',      'India', 'Standard', '2023-09-05'),
('Fatima Sheikh',      'fatima.sheikh@gmail.com',       'Pune',        'India', 'Budget',   '2023-10-23'),
('Harsh Vardhan',      'harsh.vardhan@hotmail.com',     'Noida',       'India', 'Premium',  '2023-11-11'),
('Tanvi Choudhary',    'tanvi.choudhary@gmail.com',     'Jaipur',      'India', 'Standard', '2023-12-02'),
('Akash Dubey',        'akash.dubey@gmail.com',         'Allahabad',   'India', 'Budget',   '2024-01-14'),
('Pallavi Nair',       'pallavi.nair@gmail.com',        'Kochi',       'India', 'Premium',  '2024-02-07'),
('Kunal Shah',         'kunal.shah@gmail.com',          'Ahmedabad',   'India', 'Standard', '2024-03-19'),
('Richa Srivastava',   'richa.srivastava@outlook.com',  'Lucknow',     'India', 'Budget',   '2024-04-26'),
('Aditya Kumar',       'aditya.kumar@gmail.com',        'Delhi',       'India', 'Premium',  '2024-05-08'),
('Smita Wagh',         'smita.wagh@gmail.com',          'Nashik',      'India', 'Standard', '2024-06-15'),
('Rajesh Pillai',      'rajesh.pillai@yahoo.com',       'Bengaluru',   'India', 'Budget',   '2024-07-03'),
('Chitra Subash',      'chitra.subash@gmail.com',       'Chennai',     'India', 'Premium',  '2024-08-21'),
('Mohit Arora',        'mohit.arora@gmail.com',         'Delhi',       'India', 'Standard', '2024-09-09'),
('Sunita Yadav',       'sunita.yadav@hotmail.com',      'Agra',        'India', 'Budget',   '2024-10-17'),
('Vivek Anand',        'vivek.anand@gmail.com',         'Bengaluru',   'India', 'Premium',  '2024-11-28'),
('Nandita Roy',        'nandita.roy@gmail.com',         'Kolkata',     'India', 'Standard', '2024-12-04'),
('Surya Prakash',      'surya.prakash@gmail.com',       'Hyderabad',   'India', 'Budget',   '2025-01-20'),
('Priyanka Chatterjee','priyanka.chatt@gmail.com',      'Kolkata',     'India', 'Premium',  '2025-02-13'),
('Omkar Patil',        'omkar.patil@outlook.com',       'Pune',        'India', 'Standard', '2025-03-07'),
('Zara Hussain',       'zara.hussain@gmail.com',        'Hyderabad',   'India', 'Budget',   '2025-04-01');


-- ============================================================
--  SAMPLE DATA: products (30 products)
-- ============================================================
INSERT INTO products (product_name, category, sub_category, price, cost) VALUES
('Apple iPhone 15',             'Electronics',  'Smartphones',    79999.00, 55000.00),
('Samsung Galaxy S23',          'Electronics',  'Smartphones',    54999.00, 38000.00),
('OnePlus Nord CE 3',           'Electronics',  'Smartphones',    24999.00, 17000.00),
('Sony WH-1000XM5 Headphones',  'Electronics',  'Audio',          29999.00, 18000.00),
('boAt Airdopes 141',           'Electronics',  'Audio',           1299.00,   600.00),
('Dell Inspiron 15 Laptop',     'Electronics',  'Laptops',        55000.00, 38000.00),
('HP Pavilion x360',            'Electronics',  'Laptops',        65000.00, 46000.00),
('Lenovo IdeaPad Slim 3',       'Electronics',  'Laptops',        45000.00, 31000.00),
('Canon EOS 200D Camera',       'Electronics',  'Cameras',        45000.00, 30000.00),
('Mi Smart TV 43 inch',         'Electronics',  'Televisions',    28000.00, 18500.00),
('Nike Air Max 270',            'Fashion',      'Footwear',        8995.00,  3500.00),
('Adidas Ultraboost 22',        'Fashion',      'Footwear',       12000.00,  5000.00),
('Levi\'s 511 Slim Jeans',      'Fashion',      'Men Clothing',    3499.00,  1200.00),
('Zara Floral Dress',           'Fashion',      'Women Clothing',  4999.00,  1800.00),
('Fossil Chronograph Watch',    'Fashion',      'Accessories',    12999.00,  5500.00),
('Prestige Induction Cooktop',  'Home',         'Kitchen',         3500.00,  1800.00),
('Philips Air Fryer',           'Home',         'Kitchen',         7999.00,  4200.00),
('IKEA Study Table',            'Home',         'Furniture',       8999.00,  4500.00),
('Dyson V12 Vacuum Cleaner',    'Home',         'Appliances',     43000.00, 28000.00),
('Asian Paints Interior Set',   'Home',         'Decor',           2500.00,  1100.00),
('Atomic Habits (Book)',         'Books',        'Self Help',        399.00,   120.00),
('The Psychology of Money',     'Books',        'Finance',          449.00,   140.00),
('NCERT Class 12 Set',          'Books',        'Academic',         650.00,   250.00),
('Dairy Milk Silk Hamper',      'Grocery',      'Chocolates',      1200.00,   550.00),
('Organic India Green Tea',     'Grocery',      'Beverages',        499.00,   180.00),
('Tata Coffee Premium',         'Grocery',      'Beverages',        350.00,   130.00),
('Yoga Mat (6mm)',              'Sports',       'Fitness',         1299.00,   500.00),
('Decathlon Dumbbells Set',     'Sports',       'Fitness',         2499.00,  1100.00),
('Nivia Football',              'Sports',       'Outdoor',          999.00,   400.00),
('Himalaya Face Wash',          'Beauty',       'Skincare',         199.00,    70.00);


-- ============================================================
--  SAMPLE DATA: orders (120 orders, 2022-2025)
-- ============================================================
INSERT INTO orders (customer_id, order_date, status, payment_method) VALUES
(1,  '2022-01-10', 'Delivered',  'UPI'),
(3,  '2022-01-22', 'Delivered',  'Credit Card'),
(6,  '2022-02-05', 'Delivered',  'UPI'),
(2,  '2022-02-18', 'Cancelled',  'COD'),
(9,  '2022-03-01', 'Delivered',  'Debit Card'),
(12, '2022-03-14', 'Delivered',  'Net Banking'),
(1,  '2022-04-02', 'Delivered',  'UPI'),
(5,  '2022-04-19', 'Delivered',  'Credit Card'),
(8,  '2022-05-06', 'Returned',   'UPI'),
(15, '2022-05-25', 'Delivered',  'COD'),
(3,  '2022-06-08', 'Delivered',  'UPI'),
(18, '2022-06-22', 'Delivered',  'Credit Card'),
(22, '2022-07-04', 'Delivered',  'Debit Card'),
(6,  '2022-07-17', 'Cancelled',  'UPI'),
(9,  '2022-08-01', 'Delivered',  'Net Banking'),
(24, '2022-08-20', 'Delivered',  'UPI'),
(1,  '2022-09-03', 'Delivered',  'Credit Card'),
(11, '2022-09-15', 'Delivered',  'UPI'),
(15, '2022-10-02', 'Returned',   'COD'),
(3,  '2022-10-18', 'Delivered',  'UPI'),
(27, '2022-11-05', 'Delivered',  'Credit Card'),
(6,  '2022-11-28', 'Delivered',  'UPI'),
(9,  '2022-12-10', 'Delivered',  'Net Banking'),
(12, '2022-12-25', 'Delivered',  'Credit Card'),
(30, '2023-01-07', 'Delivered',  'UPI'),
(18, '2023-01-20', 'Delivered',  'Debit Card'),
(1,  '2023-02-03', 'Delivered',  'UPI'),
(33, '2023-02-16', 'Cancelled',  'Credit Card'),
(3,  '2023-03-01', 'Delivered',  'UPI'),
(22, '2023-03-19', 'Delivered',  'COD'),
(6,  '2023-04-04', 'Delivered',  'Net Banking'),
(15, '2023-04-22', 'Delivered',  'UPI'),
(36, '2023-05-08', 'Delivered',  'Credit Card'),
(9,  '2023-05-25', 'Returned',   'Debit Card'),
(24, '2023-06-10', 'Delivered',  'UPI'),
(1,  '2023-06-28', 'Delivered',  'Credit Card'),
(39, '2023-07-12', 'Delivered',  'UPI'),
(12, '2023-07-30', 'Delivered',  'Net Banking'),
(30, '2023-08-14', 'Delivered',  'COD'),
(6,  '2023-08-27', 'Cancelled',  'UPI'),
(3,  '2023-09-09', 'Delivered',  'Credit Card'),
(42, '2023-09-24', 'Delivered',  'UPI'),
(18, '2023-10-07', 'Delivered',  'Debit Card'),
(27, '2023-10-20', 'Delivered',  'UPI'),
(9,  '2023-11-03', 'Delivered',  'Credit Card'),
(1,  '2023-11-15', 'Delivered',  'UPI'),
(45, '2023-11-28', 'Delivered',  'Net Banking'),
(15, '2023-12-10', 'Returned',   'COD'),
(33, '2023-12-23', 'Delivered',  'UPI'),
(6,  '2024-01-06', 'Delivered',  'Credit Card'),
(22, '2024-01-19', 'Delivered',  'UPI'),
(3,  '2024-02-01', 'Delivered',  'Debit Card'),
(48, '2024-02-16', 'Delivered',  'UPI'),
(9,  '2024-03-02', 'Delivered',  'Net Banking'),
(36, '2024-03-18', 'Cancelled',  'Credit Card'),
(12, '2024-04-04', 'Delivered',  'UPI'),
(1,  '2024-04-20', 'Delivered',  'COD'),
(30, '2024-05-05', 'Delivered',  'UPI'),
(42, '2024-05-22', 'Delivered',  'Credit Card'),
(6,  '2024-06-08', 'Delivered',  'Net Banking'),
(18, '2024-06-24', 'Returned',   'UPI'),
(24, '2024-07-09', 'Delivered',  'Credit Card'),
(3,  '2024-07-25', 'Delivered',  'UPI'),
(45, '2024-08-11', 'Delivered',  'Debit Card'),
(9,  '2024-08-28', 'Delivered',  'UPI'),
(1,  '2024-09-12', 'Delivered',  'Credit Card'),
(33, '2024-09-26', 'Delivered',  'COD'),
(15, '2024-10-10', 'Delivered',  'UPI'),
(27, '2024-10-24', 'Cancelled',  'Net Banking'),
(6,  '2024-11-07', 'Delivered',  'UPI'),
(48, '2024-11-18', 'Delivered',  'Credit Card'),
(12, '2024-11-29', 'Delivered',  'UPI'),
(39, '2024-12-05', 'Delivered',  'Debit Card'),
(3,  '2024-12-20', 'Delivered',  'UPI'),
(22, '2025-01-04', 'Delivered',  'Credit Card'),
(9,  '2025-01-18', 'Returned',   'UPI'),
(1,  '2025-02-01', 'Delivered',  'Net Banking'),
(36, '2025-02-14', 'Delivered',  'COD'),
(18, '2025-02-28', 'Delivered',  'UPI'),
(45, '2025-03-10', 'Delivered',  'Credit Card'),
(6,  '2025-03-22', 'Delivered',  'UPI'),
(30, '2025-04-04', 'Delivered',  'Debit Card'),
(42, '2025-04-17', 'Cancelled',  'UPI'),
(24, '2025-04-28', 'Delivered',  'Credit Card'),
(12, '2025-05-09', 'Delivered',  'UPI'),
(3,  '2025-05-20', 'Delivered',  'Net Banking'),
(48, '2025-06-02', 'Delivered',  'UPI'),
(15, '2025-06-14', 'Delivered',  'COD'),
(9,  '2025-07-01', 'Delivered',  'Credit Card'),
(1,  '2025-07-12', 'Delivered',  'UPI'),
(33, '2025-07-24', 'Delivered',  'Debit Card'),
(27, '2025-08-06', 'Delivered',  'UPI'),
(6,  '2025-08-18', 'Returned',   'Credit Card'),
(22, '2025-09-02', 'Delivered',  'UPI'),
(39, '2025-09-15', 'Delivered',  'Net Banking'),
(18, '2025-09-28', 'Delivered',  'COD'),
(3,  '2025-10-11', 'Delivered',  'UPI'),
(45, '2025-10-25', 'Delivered',  'Credit Card'),
(12, '2025-11-08', 'Delivered',  'UPI'),
(9,  '2025-11-20', 'Delivered',  'Debit Card'),
(1,  '2025-12-04', 'Delivered',  'UPI'),
(30, '2025-12-18', 'Cancelled',  'Credit Card'),
(15, '2025-12-28', 'Delivered',  'Net Banking'),
(6,  '2026-01-05', 'Delivered',  'UPI'),
(24, '2026-01-19', 'Delivered',  'COD'),
(42, '2026-02-02', 'Delivered',  'Credit Card'),
(3,  '2026-02-15', 'Delivered',  'UPI'),
(33, '2026-03-01', 'Delivered',  'Debit Card'),
(9,  '2026-03-14', 'Delivered',  'UPI'),
(18, '2026-03-27', 'Delivered',  'Net Banking'),
(1,  '2026-04-10', 'Delivered',  'Credit Card'),
(48, '2026-04-22', 'Delivered',  'UPI'),
(12, '2026-05-06', 'Delivered',  'COD'),
(27, '2026-05-18', 'Delivered',  'UPI'),
(6,  '2026-05-28', 'Delivered',  'Credit Card');


-- ============================================================
--  SAMPLE DATA: order_items (190 rows)
-- ============================================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES
(1,  1,  1, 79999.00, 0.00),
(2,  6,  1, 55000.00, 5.00),
(3,  4,  1, 29999.00, 0.00),
(4,  11, 2,  8995.00, 0.00),
(5,  2,  1, 54999.00, 8.00),
(6,  7,  1, 65000.00, 5.00),
(7,  5,  2,  1299.00, 0.00),
(7,  30, 3,   199.00, 0.00),
(8,  13, 1,  3499.00, 10.00),
(9,  10, 1, 28000.00, 0.00),
(10, 16, 1,  3500.00, 0.00),
(11, 3,  1, 24999.00, 5.00),
(12, 1,  1, 79999.00, 0.00),
(13, 21, 2,   399.00, 0.00),
(13, 22, 1,   449.00, 0.00),
(14, 27, 1,  1299.00, 0.00),
(15, 8,  1, 45000.00, 10.00),
(16, 15, 1, 12999.00, 5.00),
(17, 6,  1, 55000.00, 0.00),
(18, 17, 1,  7999.00, 0.00),
(19, 11, 1,  8995.00, 0.00),
(20, 2,  1, 54999.00, 0.00),
(21, 24, 2,  1200.00, 0.00),
(21, 25, 3,   499.00, 0.00),
(22, 1,  1, 79999.00, 5.00),
(23, 9,  1, 45000.00, 0.00),
(24, 4,  1, 29999.00, 10.00),
(25, 7,  1, 65000.00, 5.00),
(26, 14, 1,  4999.00, 0.00),
(27, 5,  3,  1299.00, 0.00),
(27, 30, 2,   199.00, 0.00),
(28, 12, 1, 12000.00, 10.00),
(29, 3,  1, 24999.00, 0.00),
(30, 28, 2,  2499.00, 5.00),
(31, 17, 1,  7999.00, 0.00),
(32, 1,  1, 79999.00, 0.00),
(33, 20, 2,  2500.00, 0.00),
(34, 2,  1, 54999.00, 8.00),
(35, 6,  1, 55000.00, 0.00),
(36, 4,  1, 29999.00, 5.00),
(37, 22, 2,   449.00, 0.00),
(37, 21, 1,   399.00, 0.00),
(38, 10, 1, 28000.00, 0.00),
(39, 13, 2,  3499.00, 0.00),
(40, 29, 1,   999.00, 0.00),
(41, 1,  1, 79999.00, 0.00),
(42, 16, 2,  3500.00, 5.00),
(43, 8,  1, 45000.00, 0.00),
(44, 27, 2,  1299.00, 0.00),
(45, 3,  1, 24999.00, 10.00),
(46, 5,  2,  1299.00, 0.00),
(46, 25, 2,   499.00, 0.00),
(47, 15, 1, 12999.00, 0.00),
(48, 9,  1, 45000.00, 5.00),
(49, 2,  1, 54999.00, 0.00),
(50, 6,  1, 55000.00, 0.00),
(51, 4,  1, 29999.00, 0.00),
(52, 1,  1, 79999.00, 5.00),
(53, 19, 1, 43000.00, 0.00),
(54, 12, 1, 12000.00, 0.00),
(55, 7,  1, 65000.00, 10.00),
(56, 17, 1,  7999.00, 0.00),
(57, 3,  1, 24999.00, 5.00),
(58, 11, 2,  8995.00, 0.00),
(59, 6,  1, 55000.00, 0.00),
(60, 2,  1, 54999.00, 8.00),
(61, 4,  1, 29999.00, 0.00),
(62, 1,  1, 79999.00, 0.00),
(63, 18, 1,  8999.00, 5.00),
(64, 5,  3,  1299.00, 0.00),
(64, 30, 4,   199.00, 0.00),
(65, 10, 1, 28000.00, 0.00),
(66, 9,  1, 45000.00, 0.00),
(67, 3,  1, 24999.00, 10.00),
(68, 13, 1,  3499.00, 0.00),
(69, 15, 1, 12999.00, 5.00),
(70, 22, 2,   449.00, 0.00),
(70, 21, 2,   399.00, 0.00),
(71, 6,  1, 55000.00, 0.00),
(72, 27, 1,  1299.00, 0.00),
(73, 1,  1, 79999.00, 0.00),
(74, 2,  1, 54999.00, 5.00),
(75, 4,  1, 29999.00, 0.00),
(76, 17, 2,  7999.00, 0.00),
(77, 8,  1, 45000.00, 0.00),
(78, 5,  2,  1299.00, 0.00),
(78, 26, 3,   350.00, 0.00),
(79, 3,  1, 24999.00, 5.00),
(80, 12, 1, 12000.00, 0.00),
(81, 16, 1,  3500.00, 0.00),
(82, 7,  1, 65000.00, 5.00),
(83, 11, 1,  8995.00, 10.00),
(84, 6,  1, 55000.00, 0.00),
(85, 1,  1, 79999.00, 0.00),
(86, 9,  1, 45000.00, 5.00),
(87, 2,  1, 54999.00, 0.00),
(88, 14, 1,  4999.00, 0.00),
(89, 4,  1, 29999.00, 10.00),
(90, 28, 2,  2499.00, 0.00),
(91, 3,  1, 24999.00, 0.00),
(92, 17, 1,  7999.00, 5.00),
(93, 6,  1, 55000.00, 0.00),
(94, 1,  1, 79999.00, 0.00),
(95, 10, 1, 28000.00, 0.00),
(96, 5,  2,  1299.00, 0.00),
(96, 30, 3,   199.00, 0.00),
(97, 15, 1, 12999.00, 0.00),
(98, 2,  1, 54999.00, 8.00),
(99, 7,  1, 65000.00, 0.00),
(100,4,  1, 29999.00, 5.00),
(101,3,  1, 24999.00, 0.00),
(102,9,  1, 45000.00, 0.00),
(103,1,  1, 79999.00, 0.00),
(104,19, 1, 43000.00, 5.00),
(105,6,  1, 55000.00, 10.00),
(106,27, 2,  1299.00, 0.00),
(107,2,  1, 54999.00, 0.00),
(108,13, 2,  3499.00, 5.00),
(109,8,  1, 45000.00, 0.00),
(110,4,  1, 29999.00, 0.00),
(111,17, 1,  7999.00, 0.00),
(112,1,  1, 79999.00, 0.00),
(113,5,  3,  1299.00, 0.00),
(113,25, 2,   499.00, 0.00),
(114,6,  1, 55000.00, 5.00),
(115,3,  1, 24999.00, 10.00),
(116,10, 1, 28000.00, 0.00),
(117,15, 1, 12999.00, 0.00),
(118,2,  1, 54999.00, 0.00),
(119,7,  1, 65000.00, 5.00),
(120,4,  1, 29999.00, 0.00);


-- ============================================================
--  SAMPLE DATA: returns (15 returns)
-- ============================================================
INSERT INTO returns (order_id, product_id, return_date, reason) VALUES
(9,  10, '2022-05-20', 'Defective product'),
(19, 11, '2022-10-18', 'Wrong size delivered'),
(34, 2,  '2023-06-05', 'Changed mind'),
(48, 9,  '2023-12-20', 'Product not as described'),
(60, 2,  '2024-07-05', 'Defective product'),
(76, 17, '2025-01-30', 'Better price found elsewhere'),
(93, 6,  '2026-08-25', 'Arrived damaged'),
(61, 2,  '2024-07-22', 'Changed mind'),
(34, 2,  '2023-06-06', 'Defective product'),
(9,  10, '2022-05-22', 'Not as expected'),
(19, 11, '2022-10-19', 'Size unavailable for exchange'),
(48, 9,  '2023-12-22', 'Damaged packaging'),
(60, 2,  '2024-07-08', 'Wrong item delivered'),
(76, 17, '2025-02-01', 'Defective product'),
(93, 6,  '2026-08-28', 'Changed mind');


-- ============================================================
--  SAMPLE DATA: marketing_campaigns (10 campaigns)
-- ============================================================
INSERT INTO marketing_campaigns (campaign_name, channel, start_date, end_date, budget_spent, customers_reached) VALUES
('New Year Mega Sale 2022',        'Email',       '2022-01-01', '2022-01-07',  45000.00, 12000),
('Valentine\'s Day Special',       'Instagram',   '2022-02-10', '2022-02-14',  28000.00,  8500),
('Summer Electronics Fest',        'Google Ads',  '2022-05-01', '2022-05-31',  95000.00, 35000),
('Diwali Bonanza 2022',            'Email',       '2022-10-15', '2022-10-24', 150000.00, 48000),
('Year End Clearance',             'SMS',         '2022-12-20', '2022-12-31',  32000.00, 15000),
('Republic Day Flash Sale',        'YouTube',     '2023-01-24', '2023-01-26',  55000.00, 22000),
('Monsoon Fashion Drop',           'Instagram',   '2023-07-01', '2023-07-15',  40000.00, 18000),
('Diwali Bonanza 2023',            'Google Ads',  '2023-11-05', '2023-11-15', 180000.00, 62000),
('New Year Mega Sale 2024',        'Email',       '2024-01-01', '2024-01-07',  52000.00, 14000),
('Independence Day Super Sale',    'Instagram',   '2024-08-10', '2024-08-15',  67000.00, 29000);


SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  VERIFY: Quick check queries
-- ============================================================
SELECT 'customers'          AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products',          COUNT(*) FROM products
UNION ALL
SELECT 'orders',            COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',       COUNT(*) FROM order_items
UNION ALL
SELECT 'returns',           COUNT(*) FROM returns
UNION ALL
SELECT 'marketing_campaigns', COUNT(*) FROM marketing_campaigns;

