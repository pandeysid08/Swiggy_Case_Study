-- Q6: Monthly orders, revenue, AOV and month-over-month growth. Window function: LAG.
WITH m AS (
    SELECT strftime('%Y-%m', order_ts) AS month, COUNT(*) AS orders, SUM(total_amount) AS revenue
    FROM orders WHERE status = 'Delivered' GROUP BY 1
)
SELECT month, orders, ROUND(revenue, 0) AS revenue, ROUND(revenue / orders, 1) AS aov,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS mom_revenue_growth_pct,
       ROUND(100.0 * (orders  - LAG(orders)  OVER (ORDER BY month)) / LAG(orders)  OVER (ORDER BY month), 1) AS mom_order_growth_pct
FROM m ORDER BY month;
