-- Data Cleaning SQL Script
-- Author: Sai Abhigna Talla
-- Description: This script cleans the dirty cafe sales data by handling missing values,
-- formatting inconsistencies, and enriching the dataset with new columns.

-- Step 1: Create a new table to store clean data
CREATE TABLE clean_cafe_sales LIKE dirty_cafe_sales;

-- Step 2: Copy data from dirty table to clean table
INSERT INTO clean_cafe_sales SELECT * FROM dirty_cafe_sales;

-- Step 3: Standardize column names and data types
ALTER TABLE clean_cafe_sales
CHANGE `Transaction ID` transaction_id VARCHAR(50),
CHANGE `Price Per Unit` price_per_unit VARCHAR(50),
CHANGE `Total Spent` total_spent VARCHAR(50),
CHANGE `Payment Method` payment_method VARCHAR(50),
CHANGE `Transaction Date` transaction_date VARCHAR(50);

-- Step 4: Check for duplicates based on transaction_id
SELECT transaction_id, COUNT(*) AS cnt
FROM clean_cafe_sales
GROUP BY transaction_id
HAVING cnt > 1;

-- Step 5: Identify and clean invalid item values
UPDATE clean_cafe_sales
SET Item = NULL
WHERE TRIM(Item) = 'ERROR' OR TRIM(Item) = 'UNKNOWN' OR TRIM(Item) = '';

-- Step 6: Identify and clean invalid numerical values
UPDATE clean_cafe_sales
SET Quantity = NULL
WHERE Quantity IS NULL
   OR TRIM(Quantity) = ''
   OR NOT Quantity REGEXP '^[0-9]+$';

UPDATE clean_cafe_sales
SET price_per_unit = NULL
WHERE price_per_unit IS NULL
   OR TRIM(price_per_unit) = ''
   OR NOT price_per_unit REGEXP '^[0-9]+(\.[0-9]+)?$';

UPDATE clean_cafe_sales
SET total_spent = NULL
WHERE total_spent IS NULL
   OR TRIM(total_spent) = ''
   OR NOT total_spent REGEXP '^[0-9]+(\.[0-9]+)?$';

-- Step 7: Correct missing Quantity and Price Per Unit values
UPDATE clean_cafe_sales
SET Quantity = (total_spent / price_per_unit),
	price_per_unit = (total_spent / Quantity),
    total_spent = (Quantity * price_per_unit);

-- Step 8: Remove rows with all NULL numeric values
DELETE FROM clean_cafe_sales
WHERE price_per_unit IS NULL 
  AND Quantity IS NULL 
  AND total_spent IS NULL;

-- Step 9: Clean Location and Payment Method fields
UPDATE clean_cafe_sales 
SET Location = NULL 
WHERE TRIM(Location) IN ('UNKNOWN', 'ERROR', '');

UPDATE clean_cafe_sales 
SET payment_method = NULL 
WHERE TRIM(payment_method) IN ('UNKNOWN', 'ERROR', '');

-- Step 10: Fill missing Location based on Payment Method
UPDATE clean_cafe_sales
SET Location = 'In-store'
WHERE Location IS NULL 
  AND payment_method = 'Cash';

UPDATE clean_cafe_sales
SET Location = 'Takeaway'
WHERE Location IS NULL 
  AND payment_method = 'Credit Card';
  
UPDATE clean_cafe_sales
SET Location = 'Takeaway'
WHERE Location IS NULL 
  AND payment_method = 'Digital Wallet';

-- Step 11: Fill missing Payment Method based on Location
UPDATE clean_cafe_sales
SET payment_method = 'Cash'
WHERE payment_method IS NULL 
  AND Location = 'In-store';
  
UPDATE clean_cafe_sales
SET payment_method = 'Credit Card'
WHERE payment_method IS NULL 
  AND Location = 'Takeaway';

UPDATE clean_cafe_sales
SET payment_method = 'Digital Wallet'
WHERE payment_method IS NULL 
  AND Location = 'In-store';

-- Step 12: Fill any remaining missing values with defaults
UPDATE clean_cafe_sales 
SET Location = 'In-store', payment_method = 'Cash'
WHERE Location IS NULL 
  AND payment_method IS NULL;

-- Step 13: Standardize and validate Transaction Dates
UPDATE clean_cafe_sales
SET Transaction_Date = NULL
WHERE TRIM(Transaction_Date) = 'ERROR'
   OR TRIM(Transaction_Date) = 'UNKNOWN'
   OR TRIM(Transaction_Date) = '';
   
UPDATE clean_cafe_sales AS t1
JOIN (
    SELECT Transaction_ID, Transaction_Date,
           @prev_date := IF(Transaction_Date IS NOT NULL, Transaction_Date, @prev_date) AS filled_date
    FROM clean_cafe_sales, (SELECT @prev_date := NULL) AS init
    ORDER BY Transaction_ID
) AS t2 ON t1.Transaction_ID = t2.Transaction_ID
SET t1.Transaction_Date = t2.filled_date
WHERE t1.Transaction_Date IS NULL;

-- Step 14: Ensure correct data types
ALTER TABLE clean_cafe_sales
MODIFY item VARCHAR(50),
MODIFY transaction_id VARCHAR(50),
MODIFY quantity INT,
MODIFY price_per_unit DECIMAL(10,2),
MODIFY total_spent DECIMAL(10,2),
MODIFY payment_method VARCHAR(50),
MODIFY location VARCHAR(50),
MODIFY transaction_date DATE;

-- Step 15: Assign missing items based on price per unit
UPDATE clean_cafe_sales 
SET item = 'TEA' 
WHERE price_per_unit = 1.50;

UPDATE clean_cafe_sales 
SET item = 'Coffee' 
WHERE price_per_unit = 2.00;

UPDATE clean_cafe_sales 
SET item = 'Cookie' 
WHERE price_per_unit = 1.00;

UPDATE clean_cafe_sales 
SET item = 'Salad' 
WHERE price_per_unit = 5.00;

UPDATE clean_cafe_sales 
SET item = 'Smoothie' 
WHERE price_per_unit = 4.00;

-- Step 16: Assign random values for unidentified items priced at 3.00
UPDATE clean_cafe_sales
SET item = CASE
    WHEN RAND() < 0.5 THEN 'Cake'
    ELSE 'Juice'
END
WHERE item IS NULL
  AND price_per_unit = 3.00;

-- Step 17: Add and populate Day of Week and Month columns
ALTER TABLE clean_cafe_sales 
ADD day_of_week VARCHAR(15), 
ADD transaction_month VARCHAR(15);

UPDATE clean_cafe_sales 
SET day_of_week = DAYNAME(transaction_date), 
	transaction_month = MONTHNAME(transaction_date);

-- Step 18: Final Data Validation
SELECT COUNT(*) AS remaining_nulls
FROM clean_cafe_sales
WHERE item IS NULL 
   OR quantity IS NULL 
   OR price_per_unit IS NULL 
   OR total_spent IS NULL 
   OR transaction_date IS NULL;

-- Step 19: Final formatted query
SELECT transaction_id AS 'Transaction ID', 
       item AS 'Item Purchased',
       quantity AS 'Quantity',
       FORMAT(price_per_unit, 2) AS 'Price per Unit ($)',
       FORMAT(total_spent, 2) AS 'Total Spent ($)',
       payment_method AS 'Payment Method',
       location AS 'Location',
       DATE_FORMAT(transaction_date, '%m/%d/%Y') AS 'Transaction Date',
       day_of_week AS 'Day',
       transaction_month AS 'Month'
FROM clean_cafe_sales
ORDER BY transaction_date;

