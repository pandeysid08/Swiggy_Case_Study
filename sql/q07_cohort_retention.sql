-- Q7: Monthly cohort retention (cohort = month of first delivered order).
WITH first AS (
    SELECT customer_id, MIN(strftime('%Y-%m', order_ts)) AS cohort
    FROM orders WHERE status = 'Delivered' GROUP BY customer_id
), act AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', order_ts) AS ym
    FROM orders WHERE status = 'Delivered'
), j AS (
    SELECT f.cohort, f.customer_id,
           (CAST(substr(a.ym,1,4) AS INTEGER) - CAST(substr(f.cohort,1,4) AS INTEGER)) * 12
           + CAST(substr(a.ym,6,2) AS INTEGER) - CAST(substr(f.cohort,6,2) AS INTEGER) AS month_n
    FROM first f JOIN act a ON a.customer_id = f.customer_id
), sz AS (SELECT cohort, COUNT(*) AS cohort_size FROM first GROUP BY cohort)
SELECT j.cohort, sz.cohort_size, j.month_n,
       COUNT(DISTINCT j.customer_id) AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT j.customer_id) / sz.cohort_size, 1) AS retention_pct
FROM j JOIN sz ON sz.cohort = j.cohort
GROUP BY j.cohort, j.month_n
ORDER BY j.cohort, j.month_n;
