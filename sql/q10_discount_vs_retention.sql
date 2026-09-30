-- Q10: Does a discounted first order lead to more repeat orders?
WITH ranked AS (
    SELECT customer_id, discount_amount,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_ts) AS rn
    FROM orders WHERE status = 'Delivered'
), first_o AS (
    SELECT customer_id,
           CASE WHEN discount_amount > 0 THEN 'Discounted first order' ELSE 'Full-price first order' END AS first_order_type
    FROM ranked WHERE rn = 1
), cnt AS (
    SELECT customer_id, COUNT(*) AS n FROM orders WHERE status = 'Delivered' GROUP BY customer_id
)
SELECT first_order_type, COUNT(*) AS customers,
       ROUND(100.0 * SUM(n >= 2) / COUNT(*), 1) AS repeat_rate_pct,
       ROUND(AVG(n), 2) AS avg_orders_per_customer
FROM first_o JOIN cnt ON cnt.customer_id = first_o.customer_id
GROUP BY first_order_type;
