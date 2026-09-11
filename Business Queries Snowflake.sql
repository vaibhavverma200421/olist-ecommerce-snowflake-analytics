-- Creating Database
CREATE DATABASE oilist_snowflake_database;


-- Creating schema 
CREATE SCHEMA oilist_snowflake_database.raw;

-- Creating customer_table


CREATE TABLE oilist_snowflake_database.raw.customers(
customer_id string,
customer_unique_id string,
customer_zip_code_prefix int,
customer_city string,
customer_state string
);


-- Creating order_table

CREATE TABLE oilist_snowflake_database.raw.orders(
order_id string,
customer_id string,
order_status string,
order_purchase_timestamp TIMESTAMP,
order_approved_at TIMESTAMP,
order_delivered_carrier_date TIMESTAMP,
order_delivered_customer_date TIMESTAMP,
order_estimated_delivery_date TIMESTAMP
);


-- Creating order_items Table

CREATE TABLE oilist_snowflake_database.raw.order_items(
order_id STRING,
order_item_id INT,
product_id STRING,
seller_id STRING,
shipping_limit_date TIMESTAMP,
price FLOAT,
freight FLOAT
);


-- Creating products table

CREATE TABLE oilist_snowflake_database.raw.products(
product_id STRING,
product_category_name STRING,
product_name_length FLOAT,
product_description_length FLOAT,
product_photos_qty FLOAT,
product_weight_g FLOAT,
product_length_cm FLOAT,
product_height_cm FLOAT,
product_weight_cm FLOAT
);


-- Creating sellers Table

CREATE TABLE oilist_snowflake_database.raw.sellers(
seller_id STRING,
seller_zip_code_prefix INT,
seller_city STRING,
seller_state STRING
);

---- All the tables are successfully created !


-- Overview of tables

--customer table

SELECT * FROM customers
LIMIT 5;

-- orders table

SELECT * FROM orders
LIMIT 5;

-- order_items table

SELECT * FROM order_items
LIMIT 5;

-- products table

SELECT * FROM products
LIMIT 5;

-- sellers Table

SELECT * FROM sellers
LIMIT 5;


-- Business Queries 

--> Q1. State-wise total revenue nikaalo (highest se lowest).

SELECT 
       c.customer_state,
       ROUND(SUM(oi.price + oi.freight)) AS revenue
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state 
ORDER BY revenue DESC;


--> Q2. Har product category ka rank nikaalo total sales ke hisaab se (top 5 dikhao).

SELECT 
      p.product_category_name,
      ROUND(SUM(oi.price + oi.freight)) AS total_revenue,
      RANK() OVER(ORDER BY ROUND(SUM(oi.price * oi.freight)) DESC) AS rnk
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id 
GROUP BY p.product_category_name
LIMIT 5;



--> Q3. Wo sellers dhundo jinka average selling price overall average se zyada hai.

-- QUICK OVERVIEW 
SELECT * FROM sellers LIMIT 4;
SELECT * FROM order_items LIMIT 4;

WITH seller_AVG_price_CTE AS(
SELECT 
       seller_id,
       AVG(price) AS average_price
FROM order_items
GROUP by seller_id
),
overall_average_price_CTE AS(
SELECT 
      AVG(average_price) AS overall_average
FROM seller_AVG_price_CTE
)
SELECT 
      ap.seller_id,
      ap.average_price,
      op.overall_average
FROM seller_avg_price_cte ap
CROSS JOIN overall_average_price_CTE op
WHERE ap.average_price > op.overall_average
ORDER BY ap.average_price DESC;


--> Q4. Har customer ka pehla order dhundo (order date ke hisaab se).

SELECT 
    customer_id,
    MIN(order_purchase_timestamp) AS first_order_date
FROM orders
GROUP BY customer_id
ORDER BY first_order_date;



--> Q5. Ek naya column add karo jo flag kare ki order "high value" hai ya nahi (price > 500), phir usse update karo.

-- Creating column
ALTER TABLE oilist_snowflake_database.raw.order_items
ADD COLUMN order_value string;

-- specifying values inside it
UPDATE order_items
SET order_value  = CASE
                        WHEN price > 500 THEN 'High_value_orders'
                        ELSE 'normal'
                    END;

-- Verifying
SELECT 
       price,
       order_value
FROM order_items
LIMIT 10;

-- COLUMN CREATED   



--> Q6. Har order ke liye pichle order ke comparison mein kitna time gap tha (days mein) — per customer.

--overview
SELECT * FROM orders LIMIT 5;

WITH orders_cte AS(
SELECT 
      c.customer_id,
      c.customer_unique_id,
      o.order_id,
      o.order_purchase_timestamp,
      LAG(o.order_purchase_timestamp) OVER(PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS previous_order_date
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id      
)
SELECT 
      customer_id,
      customer_unique_id,
      order_id,
      previous_order_date,
      order_purchase_timestamp,
      DATEDIFF('day', previous_order_date, order_purchase_timestamp) AS gap_days
FROM orders_cte
ORDER BY customer_id, order_purchase_timestamp;


--> Q7. Wo products dhundo jinki price average product price se zyada hai.

SELECT * FROM products LIMIT 5;

WITH product_price_cte AS(
SELECT
       p.product_id,
       oi.price AS product_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
) 
SELECT 
       product_id,
       product_price
FROM product_price_cte 
WHERE product_price > (SELECT AVG(product_price) FROM product_price_cte)
ORDER BY product_price DESC;


--> Q8. Har state ke top 3 sabse zyada order-count wale customers dhundo (nested/double window function).

SELECT * FROM  orders LIMIT 4;

WITH order_count_CTE AS(
SELECT 
       c.customer_unique_id,
       c.customer_state,
       COUNT(o.order_id) AS total_orders_count,
       DENSE_RANK() OVER(PARTITION BY c.customer_state ORDER BY COUNT(o.order_id) DESC) AS customer_rank
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state, c.customer_unique_id
)
SELECT 
      customer_state,
      customer_unique_id,
      total_orders_count,
      customer_rank
FROM order_count_CTE
WHERE customer_rank <= 3
ORDER BY customer_state, customer_rank;



--> Q9. Running total (cumulative revenue) nikaalo month-wise.

SELECT * FROM orders LIMIT 5;

WITH monthly_revenue AS(
SELECT 
       TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS Month,
       ROUND(SUM(oi.price + oi.freight)) AS revenue
FROM orders o 
JOIN order_items oi ON oi.order_id = o.order_id 
GROUP BY Month
ORDER BY Month
)
SELECT 
      Month,
      revenue,
      SUM(revenue) OVER(ORDER BY Month) AS running_total
FROM monthly_revenue;


--> Q10. Un order_items rows ko delete karo jinka price 1 rupee se kam hai (data-quality cleanup, hypothetical) — DELETE + subquery.

SELECT COUNT(*) FROM order_items WHERE  price < 1;

DELETE FROM order_items
WHERE price < 1;


--> Q11. Har state mein "delivered" vs "canceled" orders ka count — PIVOT table jaisa format mein.

SELECT DISTINCT order_status FROM orders;

SELECT 
      c.customer_state,
      o.order_status,
      COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered_orders,
      COUNT(CASE WHEN order_status = 'canceled' THEN 1  END) AS canceled_orders
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state, o.order_status;


--> Q12. Un customers ko dhundo jinhone kabhi koi order nahi kiya (agar exist karte hon) — NOT EXISTS se.

SELECT 
      c.customer_id,
      c.customer_city,
      o.order_id
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;   


--> Q13. Un sellers ko dhundo jinhone 50 se zyada orders kiye HAIN aur unka average price bhi 100 se zyada hai.


WITH seller_order_CTE AS(
SELECT 
      s.seller_id,
      COUNT(oi.order_id) AS total_orders,
      AVG(oi.price) AS average_price
FROM sellers s 
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
)
SELECT 
       seller_id,
       total_orders,
       average_price
FROM seller_order_cte
WHERE total_orders > 50 AND average_price > 100
ORDER BY total_orders DESC;


--> Q14. Ek naya table banao jisme sirf "high-value customers" (jinka total spend > 1000) store ho — MERGE se insert/update dono handle karo.


CREATE TABLE high_value_customers(
customer_id STRING,
customer_unique_id STRING,
total_spend INT
);

-- Using merge

-- MERGE INTO high_value_customers h
-- USING(
-- SELECT 
--        c.customer_id,
--        c.customer_unique_id,
--        ROUND(SUM(oi.price * oi.freight),2) AS total_revenue
-- FROM customers c 
-- JOIN order_items oi ON c.customer_id = oi.customer_id
-- GROUP BY c.customer_id, c.customer_unique_id
-- HAVING ROUND(SUM(oi.price * oi.freight),2) > 1000
-- ) s    -- alias of sub query
-- ON t.customer_id = s.customer_id
-- WHEN 


INSERT INTO high_value_customers (customer_id, total_spend)
SELECT o.customer_id, SUM(oi.price) AS total_spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.customer_id
HAVING SUM(oi.price) > 1000;

SELECT * FROM high_value_customers LIMIT 10;



-->  Q15. Ek View banao jo state-wise monthly revenue dikhaye — Power BI dashboard ke liye reusable.

CREATE VIEW monthly_state_revenue AS
SELECT 
      c.customer_state,
      TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS Month,
      ROUND(SUM(oi.price + oi.freight)) AS total_revenue,
      COUNT(DISTINCT oi.order_id) AS total_orders
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state, TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
ORDER BY Month
LIMIT 10;

SELECT * FROM monthly_state_revenue
LIMIT 10;


--> Q16. Customers ko unke total spend ke hisaab se 4 equal groups (quartiles) mein baato — NTILE se.

SELECT * FROM order_items LIMIT 5;


WITH customer_spend_CTE AS(
SELECT 
       c.customer_id,
       c.customer_unique_id,
       ROUND(SUM(oi.price + oi.freight)) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_unique_id
)
SELECT 
      customer_id,
      customer_unique_id,
      total_spend,
      NTILE(4) OVER(ORDER BY total_spend DESC) AS spend_quartile
FROM customer_spend_cte;


--> Q17. Un customers ko dhundo jinhone 2017 mein order kiya THA lekin 2018 mein nahi kiya — set operation se.

SELECT 
      DISTINCT o.customer_id
FROM orders o 
WHERE YEAR(order_purchase_timestamp) = 2017

EXCEPT

SELECT DISTINCT o.customer_id
FROM orders o 
WHERE YEAR(order_purchase_timestamp) = 2018;


-->  Q19. Un orders ko dhundo jinme kam se kam ek product "high value" (>500) tha — EXISTS se.

SELECT 
        oi.order_id
FROM order_items oi 
WHERE oi.price > 500;


--> Q20. Har seller ka contribution % nikaalo total company revenue mein se.

-- overview
SELECT * FROM order_items LIMIT 5;


WITH revenue_CTE AS(
SELECT 
      s.seller_id,
      SUM(oi.price) AS total_revenue
FROM sellers s 
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
)
SELECT 
      seller_id,
      total_revenue,
      ROUND(total_revenue * 100 / SUM(total_revenue) OVER(),2) AS pct_of_total_revenue
FROM revenue_cte
ORDER BY pct_of_total_revenue DESC
LIMIT 10;


--> Q21. State-wise revenue + ek grand total row bhi saath mein — ROLLUP se.

SELECT 
      c.customer_state,
      SUM(oi.price + oi.freight) AS total_revenue,
FROM  customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY ROLLUP(c.customer_state)
ORDER BY c.customer_state;


--> Q22. Har seller ke top 3 order_ids ko ek single comma-separated string mein dikhao.

SELECT * FROM order_items LIMIT 5;

WITH orders_CTE AS(
SELECT 
      s.seller_id,
      oi.order_id,
      SUM(oi.price) AS revenue,
      RANK() OVER(PARTITION BY s.seller_id ORDER BY SUM(oi.price) DESC) AS rnk
FROM sellers s 
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, oi.order_id
)
SELECT 
      seller_id,
      order_id,
      revenue,
      rnk
FROM orders_CTE
WHERE rnk <= 4;


--> Q23. Ek naya summary table banao seedha query result se — CTAS (Create Table As Select).

 CREATE OR REPLACE TABLE state_revenue_summary AS
SELECT 
        c.customer_state,
        SUM(oi.price * oi.freight) AS total_revenue,
        COUNT(oi.order_id) AS total_orders
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

SELECT * FROM state_revenue_summary
LIMIT 10;


--> Q24.Q25. Same city mein located do-do sellers ke pairs dhundo — Self-JOIN se.

SELECT  
       s1.seller_id AS seller_1,
       s2.seller_id AS seller_2,
       s1.seller_city
FROM sellers s1
JOIN sellers s2 ON s1.seller_id = s2.seller_id
ORDER BY s1.seller_city;


--> Q25. State aur category dono ke combinations ka revenue ek saath dikhao, alag-alag bhi aur combined bhi — GROUPING SETS se.

SELECT 
      c.customer_state,
      p.product_category_name,
      SUM(oi.price) AS revenue
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY GROUPING SETS(
(c.customer_state, p.product_category_name),
(c.customer_state),
()
)
ORDER BY c.customer_state, p.product_category_name;



-- extra queries : For verfying Power BI Measures Values.

-- Total orders
SELECT COUNT (order_id) AS total_orders FROM order_items;


-- AOV Average Order Value
WITH total_order_and_revenue_CTE AS(
SELECT 
      COUNT(DISTINCT o.order_id) AS total_orders,
      SUM(oi.price) AS total_revenue
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
)
SELECT 
      ROUND(total_revenue/total_orders) AS AOV
FROM  total_order_and_revenue_cte;


-- Total Unique customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers FROM customers;

-- Total delivered orders
SELECT DISTINCT order_status FROM orders;

SELECT COUNT(*) FROM orders
WHERE order_status = 'delivered';



      
