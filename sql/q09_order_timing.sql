-- Q9: When do people order? Daypart x weekday/weekend.
SELECT CASE WHEN CAST(strftime('%H', order_ts) AS INTEGER) BETWEEN 6  AND 10 THEN '1 Breakfast (6-10)'
            WHEN CAST(strftime('%H', order_ts) AS INTEGER) BETWEEN 11 AND 15 THEN '2 Lunch (11-15)'
            WHEN CAST(strftime('%H', order_ts) AS INTEGER) BETWEEN 16 AND 18 THEN '3 Snacks (16-18)'
            WHEN CAST(strftime('%H', order_ts) AS INTEGER) BETWEEN 19 AND 22 THEN '4 Dinner (19-22)'
            ELSE '5 Late night' END AS daypart,
       CASE WHEN strftime('%w', order_ts) IN ('0','6') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*) AS orders, ROUND(AVG(total_amount), 0) AS avg_order_value
FROM orders WHERE status = 'Delivered'
GROUP BY daypart, day_type ORDER BY daypart, day_type;
