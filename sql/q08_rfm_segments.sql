-- Q8: RFM-style customer segments using NTILE quartiles.
WITH ref AS (SELECT MAX(DATE(order_ts)) AS d FROM orders),
base AS (
    SELECT customer_id,
           julianday((SELECT d FROM ref)) - julianday(MAX(DATE(order_ts))) AS recency_days,
           COUNT(*) AS frequency, SUM(total_amount) AS monetary
    FROM orders WHERE status = 'Delivered' GROUP BY customer_id
), scored AS (
    SELECT *, NTILE(4) OVER (ORDER BY recency_days DESC) AS r,
              NTILE(4) OVER (ORDER BY frequency)         AS f
    FROM base
)
SELECT CASE WHEN r >= 3 AND f >= 3 THEN 'Champions (recent + frequent)'
            WHEN r >= 3 AND f <= 2 THEN 'New / Promising'
            WHEN r <= 2 AND f >= 3 THEN 'At Risk (was frequent, gone quiet)'
            ELSE 'Hibernating' END AS segment,
       COUNT(*) AS customers, ROUND(AVG(recency_days), 0) AS avg_recency_days,
       ROUND(AVG(frequency), 1) AS avg_orders, ROUND(SUM(monetary), 0) AS revenue
FROM scored GROUP BY segment ORDER BY revenue DESC;
