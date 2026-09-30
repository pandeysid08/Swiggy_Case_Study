-- Q5: Top 3 restaurants per city by revenue, with repeat-customer rate. Window function: RANK.
WITH cr AS (
    SELECT restaurant_id, customer_id, COUNT(*) AS n, SUM(total_amount) AS rev
    FROM orders WHERE status = 'Delivered' GROUP BY restaurant_id, customer_id
), agg AS (
    SELECT restaurant_id, SUM(n) AS orders, SUM(rev) AS revenue, COUNT(*) AS customers,
           SUM(CASE WHEN n >= 2 THEN 1 ELSE 0 END) AS repeat_customers
    FROM cr GROUP BY restaurant_id
), ranked AS (
    SELECT r.name, r.city, r.cuisine, r.rating, a.orders, ROUND(a.revenue, 0) AS revenue,
           a.customers, ROUND(100.0 * a.repeat_customers / a.customers, 1) AS repeat_rate_pct,
           RANK() OVER (PARTITION BY r.city ORDER BY a.revenue DESC) AS city_rank
    FROM agg a JOIN restaurants r ON r.restaurant_id = a.restaurant_id
)
SELECT * FROM ranked WHERE city_rank <= 3 ORDER BY city, city_rank;
