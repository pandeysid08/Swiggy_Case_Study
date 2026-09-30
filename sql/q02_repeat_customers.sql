-- Q2: Repeat vs one-time customers and their share of revenue.
WITH cust AS (
    SELECT customer_id, COUNT(*) AS n_orders, SUM(total_amount) AS spend
    FROM orders WHERE status = 'Delivered' GROUP BY customer_id
)
SELECT CASE WHEN n_orders = 1 THEN '1 order'
            WHEN n_orders BETWEEN 2 AND 4 THEN '2-4 orders'
            WHEN n_orders BETWEEN 5 AND 9 THEN '5-9 orders'
            ELSE '10+ orders' END AS segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
       ROUND(AVG(spend), 0) AS avg_spend,
       ROUND(100.0 * SUM(spend) / SUM(SUM(spend)) OVER (), 1) AS pct_revenue
FROM cust
GROUP BY segment
ORDER BY MIN(n_orders);
