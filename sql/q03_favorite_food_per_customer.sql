-- Q3: Each customer's favourite food (most units ordered). Window function: ROW_NUMBER.
WITH food_counts AS (
    SELECT o.customer_id, m.item_name, SUM(oi.quantity) AS times_ordered
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN menu_items m   ON m.item_id = oi.item_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, m.item_name
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY times_ordered DESC, item_name) AS rn
    FROM food_counts
)
SELECT item_name AS favorite_food, COUNT(*) AS customers,
       ROUND(AVG(times_ordered), 1) AS avg_units_by_fans
FROM ranked WHERE rn = 1
GROUP BY item_name
ORDER BY customers DESC
LIMIT 10;
