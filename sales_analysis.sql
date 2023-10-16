-- Customer and Sales Data

-- To watch the video version of this project, please click on the link: https://www.youtube.com/watch?v=0Ds_mGiw_3s

-- For this project, i used the Sales and Customer data from Kaggle: https://www.kaggle.com/datasets/dataceo/sales-and-customer-data?select=customer_data.csv

/* 
In this project, I will be answering the following questions:

  1.  What is the total revenue generated?
  2.  What is the most popular product category in terms of sales?
  3. What are the three top shopping malls in terms of sales revenue?
  4. What is the gender distribution across different product categories?
  5. What is the age distribution of customers who prefer each payment method?

Before answering these questions, my goal is to create one source of truth by combining the two sources provided. This will simplify querying the data and will create a better organisation and viewing experience.

*/

-- Step zero: Data Exploration

SELECT *
FROM emilio-playground.raw.raw_customer
LIMIT 100;

SELECT *
FROM emilio-playground.raw.raw_sales
LIMIT 100;

-- This data has some pretty interesting information, including: customer age, product type, payment method, and price. I want to check if there is one row per invoid-id or multiple.

SELECT
invoice_no
, COUNT(*) AS count
FROM emilio-playground.raw.raw_sales
GROUP BY 1
HAVING count > 2

--output: none. This proves that there is only one invoice-id per row, therefore there are no duplicates and we do not have to worry about eliminating these in the data clearning process. Great!


-- Step one: Clean the data

-- I will begin my joining the data from the customer table to the sales table under the alias 'customer_sales_data'

CREATE OR REPLACE TABLE `core.sales_customer_data` AS (
SELECT 
  s.customer_id
  , s.category
  , s.quantity
  , s.price
  , s.quantity * s.price AS total_price
  , s.invoice_date
  , s.shopping_mall
  , c.gender
  , c.age
  , c.payment_method
FROM emilio-playground.raw.raw_sales AS s
INNER JOIN emilio-playground.raw.raw_customer AS c
ON c.customer_id = s.customer_id);

/* I added the total price in case of a purchase with more than one quantity. The text formatting seems to be consistent across columns, so there is no need to LOWER or UPPER each one. 
We have the same amount of rows after the joining, which means we are in the clear and there is no sign of duplication due to the join.  Additionally, there is a 100% joining rate.

Next, I will check for Null values in the total_price column as this was a custom computed column which we will use for later analysis. */

SELECT *
FROM emilio-playground.core.sales_customer_data
WHERE total_price IS NULL;

-- Output: 0. Excellent, there are no Null values in this column.

-- Step two: Analyse the data

-- Question one:  What is the total revenue generated in the year 2022?

SELECT SUM(total_price) AS total_revenue
FROM emilio-playground.core.sales_customer_data
WHERE EXTRACT(year FROM invoice_date) = 2022;

/* 
Output: 115,436,814.08. 
*/

-- Quesiton two:   What is the most popular product category in terms of sales?
SELECT
  SUM(quantity) AS total_quantity
 , category
FROM emilio-playground.core.sales_customer_data
GROUP BY category
ORDER BY total_quantity DESC;


/* 
Output: Clothing was the most popular product cateory in terms of sales by more than double the 2nd place cosmetics category.

1. Clothing: 103558
2. Cosmetics: 45465
3. Food & Beverage: 44277
4. Toys: 30321
5. Shoes: 30217
6. Technology: 15021
7. Book: 14982
8. Souvenir: 14871


*/

-- Quesiton three: What are the three top shopping malls in terms of sales revenue?

SELECT
  shopping_mall
  , ROUND(SUM(total_price),2) AS total_price
  FROM emilio-playground.core.sales_customer_data
  GROUP BY shopping_mall
  ORDER BY total_price DESC
  LIMIT 3;


/*
Output: The top three highest sales revenue shopping malls are the following:

1.	Mall of Istanbul: 50872481.68
2.	Kanyon: 50554231.1
3	  Metrocity: 37302787.33
*/


-- Question four: What is the gender distribution across different product categories?

SELECT
  category
  , gender
  , COUNT(*) AS count
  FROM emilio-playground.core.sales_customer_data
GROUP BY gender, category
 ORDER BY count DESC;

/*

Output:  Females purchased more than men in every single category... Surprising?? 

Clothing: Female = 20652, Male= 13835
Cosmetics: Female= 9070, Male= 6027
Food & Beverage: Female = 8804, Male= 5972
Toys: Female = 6085, Male= 4002
Technology: Female= 2981, Male= 2015
*/

-- Question five: What is the age distribution of customers who prefer each payment method?
SELECT
  CASE WHEN age BETWEEN 0 AND 25 THEN '0-25'
       WHEN age BETWEEN 26 AND 50 THEN '26-50'
       WHEN age BETWEEN 51 AND 75 THEN '51-75'
       WHEN age BETWEEN 76 AND 100 THEN '76-100'
       ELSE 'other' 
       END AS age_range
  ,payment_method 
  ,COUNT(*) AS count
  FROM emilio-playground.core.sales_customer_data
 GROUP BY age_range, payment_method
 ORDER BY count DESC;

/* 
Output: 

| Age Range | Payment Method | Count |
|-----------|----------------|--------|
| 26-50     | Cash           | 21,395 |
| 26-50     | Credit Card    | 16,819 |
| 51-75     | Cash           | 16,169 |
| 51-75     | Credit Card    | 12,660 |
| 26-50     | Debit Card      | 9,727 |
| 51-75     | Debit Card      | 7,225 |
| 0-25      | Cash            | 6,833 |
| 0-25      | Credit Card     | 5,419 |
| 0-25      | Debit Card      | 3,091 |
| Other     | Cash               | 50 |
| Other     | Debit Card         | 36 |
| Other     | Credit Card        | 33 |

1. The age group 26-50 uses Cash as a payment method the most, followed by Credit Card and Debit Card.
2. The age group 51-75 has a similar trend where they use Cash the most, followed by Credit Card and then Debit Card.
3. The age group 0-25 prefers to use Cash, then Credit Card, and Debit Card comes last.
4. The "Other" age group uses Cash the most, though the counts are very low for all payment methods in this category.
 
Overall, across all age groups, the use of Cash is dominant, followed by Credit Card and Debit Card. 

-- Step three: Conclusions

/*
Based on the comprehensive analysis of the Sales and Customer data:
 
1. The total revenue generated in the year 2022 was $115,436,814.08.
2. The most popular product category in terms of sales was 'Clothing' with 103,558 units sold, significantly outperforming other categories.
3. The top three shopping malls with the highest sales revenue were:
- Mall of Istanbul: $50,872,481.68
- Kanyon: $50,554,231.1
- Metrocity: $37,302,787.33
4. Gender-wise, females consistently purchased more across all product categories, particularly dominating in the 'Clothing' and 'Cosmetics' categories.
5. In terms of payment preferences:
- The age group 26-50 predominantly used Cash, followed by Credit Card and Debit Card.
- The age group 51-75 mirrored this trend, preferring Cash, then Credit Card and subsequently Debit Card.
- Those aged 0-25 primarily utilized Cash, with Credit Card and Debit Card following.
- Despite the counts being relatively low in the "Other" age group, Cash remained the dominant choice, ahead of both Credit and Debit Cards.
 
In essence, the data reflects a strong preference for 'Clothing' across shoppers, and a consistent inclination towards using Cash as a mode of payment across different age groups.
*/


Thank you for reading this SQL project, I appreciate it! */
