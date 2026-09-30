-- Q4: Top foods by revenue with breadth of demand (distinct customers).
SELECT m.item_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price), 0) AS revenue,
       COUNT(DISTINCT o.customer_id) AS distinct_customers
FROM order_items oi
JOIN orders o     ON o.order_id = oi.order_id AND o.status = 'Delivered'
JOIN menu_items m ON m.item_id = oi.item_id
GROUP BY m.item_name
ORDER BY revenue DESC
LIMIT 10;
