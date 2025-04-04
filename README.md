# Cafe Sales Data Cleaning Project

## Project Overview
- This project aims to clean and prepare a dataset of cafe sales transactions using SQL. The original dataset contained issues such as inconsistent formatting, missing values, duplicate records, and incorrect data entries. The goal is to ensure data accuracy, consistency, and usability for future analysis.

## Dataset Information
- **Source**: The dataset was obtained from Kaggle. You can find it [`here`](https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training).
- **Raw Dataset**: [`Raw Dataset`](./dirty_cafe_sales.csv)
- **Clean Dataset**: [`Clean Dataset`](./clean_cafe_sales.csv)
- **SQL Script**: [`Cleaning Script`](./cafe_datacleaning_script.sql)

## Data Cleaning Steps

### 1. Data Import and Initial Exploration
To preserve the raw data, we created a copy of the original table, naming it clean_cafe_sales. This approach allows for safe modifications without affecting the source data.

```sql
CREATE TABLE clean_cafe_sales LIKE dirty_cafe_sales;
INSERT INTO clean_cafe_sales SELECT * FROM dirty_cafe_sales;
```

### 2. Removing Duplicates
Duplicates were identified by checking for repeated transaction IDs. We removed any duplicate records to ensure each transaction is unique.

```sql
SELECT transaction_id, COUNT(*) AS cnt
FROM clean_cafe_sales
GROUP BY transaction_id
HAVING cnt > 1;
```
  
### 3. Handling Missing and Incorrect Values
We identified and corrected missing or invalid values in critical columns like Item, Quantity, Price Per Unit, Total Spent, Location, Transaction Dates, and Payment Method. Placeholder values ('UNKNOWN', 'ERROR', '') were replaced with NULL for clarity.

```sql
UPDATE table_name
SET column = NULL
WHERE TRIM(column) = 'UNKNOWN' OR TRIM(column) = 'ERROR' OR TRIM(column) = '';
```

### 4. Calculating Missing Values
Some records had incomplete information (e.g., missing quantity or price). We calculated the missing data when possible to avoid data loss.

```sql
UPDATE clean_cafe_sales
SET Quantity = (total_spent / price_per_unit),
	  price_per_unit = (total_spent / Quantity),
    total_spent = (Quantity * price_per_unit);
```

### 5. Standardize and Validate Transaction Dates
To ensure consistency, erroneous date values were removed and missing dates were filled with the most recent valid date.

```sql
UPDATE clean_cafe_sales AS t1
JOIN (
    SELECT Transaction_ID, Transaction_Date,
           @prev_date := IF(Transaction_Date IS NOT NULL, Transaction_Date, @prev_date) AS filled_date
    FROM clean_cafe_sales, (SELECT @prev_date := NULL) AS init
    ORDER BY Transaction_ID
) AS t2 ON t1.Transaction_ID = t2.Transaction_ID
SET t1.Transaction_Date = t2.filled_date
WHERE t1.Transaction_Date IS NULL;
```

### 6. Assign Missing Items Based on Price Per Unit
- We assign item names based on known price values to fill missing item data. For missing item names priced at 3.00, we randomly assigned 'Cake' or 'Juice' to retain valuable data.

```sql
UPDATE clean_cafe_sales
SET item = CASE
    WHEN RAND() < 0.5 THEN 'Cake'
    ELSE 'Juice'
END
WHERE item IS NULL AND price_per_unit = 3.00;
```

### 7. Ensure Correct Data Types
We enforced appropriate data types to maintain data integrity and prevent errors during analysis.
  
```sql
ALTER TABLE clean_cafe_sales
MODIFY item VARCHAR(50),
MODIFY transaction_id VARCHAR(50),
MODIFY quantity INT,
MODIFY price_per_unit DECIMAL(10,2),
MODIFY total_spent DECIMAL(10,2),
MODIFY payment_method VARCHAR(50),
MODIFY location VARCHAR(50),
MODIFY transaction_date DATE;
```
### 8. Add and Populate Day of Week and Month Columns
To facilitate time-based analysis, we added columns for the day of the week and transaction month.

```sql
ALTER TABLE clean_cafe_sales 
ADD day_of_week VARCHAR(15), 
ADD transaction_month VARCHAR(15);

UPDATE clean_cafe_sales 
SET day_of_week = DAYNAME(transaction_date), 
    transaction_month = MONTHNAME(transaction_date);
```

## Running the SQL Script
To execute the cleaning process, run the following command in MySQL:

```sql
SOURCE cafe_datacleaning_script.sql;
```

## Results and Output
- The cleaned dataset is stored in [`clean_cafe_sales.csv`](./clean_cafe_sales.csv), which is now ready for analysis. The dataset now has standardized data types, corrected missing values, and no duplicate entries.

## Next Steps
- Perform exploratory data analysis using Tableau.
- Generate insights from the cleaned dataset, such as sales trends, customer behavior, and location-based analysis.



