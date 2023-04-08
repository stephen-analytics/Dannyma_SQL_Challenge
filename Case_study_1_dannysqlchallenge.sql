-- Information regarding the data_type of the fields in the sales table.
SELECT column_name,data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'sales';

-- Information regarding the data_type of the fields in the menu table.
SELECT column_name,data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'menu';

-- Information regarding the data_type of the fields in the member table.
SELECT column_name,data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'member';


-- 1. What is the total amount each customer spent at the restaurant
SELECT s.customer_id,  
       SUM(m.price) AS total_amount
FROM sales s
LEFT JOIN menu m
USING(product_id)
GROUP BY s.customer_id
ORDER BY total_amount DESC;


---- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Number_of_days_visited
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_purchase_date
    FROM sales
    GROUP BY 1
    )

  SELECT DISTINCT f.customer_id, 
        s.product_id, 
        m.product_name, 
        f.first_purchase_date
  FROM first_purchase f
  LEFT JOIN sales s
  ON f.customer_id = s.customer_id
  AND f.first_purchase_date = s.order_date
  LEFT JOIN menu m
  USING(product_id)
  ORDER BY customer_id

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,  
       COUNT(*) AS count
FROM sales
JOIN menu 
USING(product_id)
GROUP BY product_name
ORDER BY count DESC
LIMIT 1;
  

  -- 5. Which item was the most popular for each customer?

WITH ranked_fav_item AS (
          SELECT customer_id, 
                product_name,
                COUNT(*) AS count, 
                DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rank
          FROM sales s
          JOIN menu m
          ON s.product_id = m.product_id
          GROUP BY 1,2
          ORDER BY customer_id)
          
SELECT customer_id, product_name, count
FROM ranked_fav_item
WHERE rank = 1


 -- 6. Which item was purchased first by the customer after they became a member?
 
WITH ranked_table AS (
      SELECT m.customer_id, product_name,
            DENSE_RANk() OVER(PARTITION BY m.customer_id ORDER BY order_date) AS rank
     FROM members m
     JOIN sales s
     ON m.customer_id = s.customer_id
     AND m.join_date <= s.order_date
     JOIN menu 
     USING(product_id)
     ORDER BY customer_id)
     
  SELECT customer_id,product_name
  FROM ranked_table
  WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?
 WITH ranked_table AS (
      SELECT m.customer_id, product_name,
            DENSE_RANk() OVER(PARTITION BY m.customer_id ORDER BY order_date DESC) AS rank
     FROM members m
     LEFT JOIN sales s
     ON m.customer_id = s.customer_id
     AND m.join_date > s.order_date
     LEFT JOIN menu 
     USING(product_id)
     ORDER BY customer_id)
     
  SELECT customer_id,product_name
  FROM ranked_table
  WHERE rank = 1;

 -- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_items, SUM(price) AS total_amount
FROM sales s
JOIN members  m
ON m.customer_id = s.customer_id
AND m.join_date > s.order_date
JOIN menu 
ON  menu.product_id = s.product_id
GROUP BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_table AS (
    SELECT customer_id, 
           product_name,
           price,
           CASE 
                WHEN product_name = 'sushi' THEN price*20 
                ELSE price*10 END AS point
    FROM sales
    JOIN menu
    USING(product_id)
  )
  
  SELECT customer_id, SUM(point) AS total_point
  FROM points_table
  GROUP BY customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH updated_points_table AS(
SELECT s.customer_id, 
           product_name,
           price,
           order_date,
           join_date,
           CASE 
                WHEN product_name = 'sushi' THEN price*20 
                WHEN order_date BETWEEN join_date AND join_date+ INTERVAL'6 days' THEN price*20 
                ELSE price*10 END AS point
    FROM sales s
    JOIN menu m
    ON s.product_id = m.product_id
    JOIN members 
    ON members.customer_id = s.customer_id
    WHERE EXTRACT(MONTH FROM order_date) = 1
)
    
    SELECT customer_id, SUM(point) AS total_points
    FROM updated_points_table
    GROUP BY customer_id

-- Bonus Question
-- 1.
SELECT customer_id,
       order_date, 
       product_name, 
       price,
       CASE 
          WHEN order_date >= join_date THEN 'Y'
          ELSE 'N' END AS member
FROM sales
LEFT JOIN members
USING(customer_id)
LEFT JOIN menu
USING(product_id)
ORDER BY customer_id, order_date;

-- 2.
WITH new_table AS (
 SELECT customer_id,
     order_date, 
     product_name, 
     price,
     CASE 
     WHEN order_date >= join_date THEN 'Y'
     ELSE 'N' END AS member 
 FROM sales
 LEFT JOIN members
 USING(customer_id)
 LEFT JOIN menu
 USING(product_id)
)

SELECT *, CASE WHEN member = 'Y' 
      THEN DENSE_RANK()OVER(PARTITION BY customer_id, member ORDER BY order_date)
      ELSE NULL END AS ranking
FROM new_table;
