-- Q1: Inactive users: customers whose last delivered order was 60+ days before the dataset end.
WITH ref AS (SELECT MAX(DATE(order_ts)) AS ref_date FROM orders),
last_order AS (
    SELECT c.customer_id, c.city,
           MAX(DATE(o.order_ts)) AS last_order_date,
           COUNT(o.order_id)     AS lifetime_orders,
           ROUND(SUM(o.total_amount), 0) AS lifetime_spend
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Delivered'
    GROUP BY c.customer_id, c.city
)
SELECT l.customer_id, l.city, l.last_order_date, l.lifetime_orders, l.lifetime_spend,
       CAST(julianday(r.ref_date) - julianday(l.last_order_date) AS INTEGER) AS days_since_last_order
FROM last_order l CROSS JOIN ref r
WHERE julianday(r.ref_date) - julianday(l.last_order_date) >= 60
ORDER BY l.lifetime_spend DESC;
