-- Filename: test_heavy_joins.sql
-- Description: Intentionally messy SQL to trigger architectural AI checks

SELECT * FROM orders o, customers c
WHERE o.customer_id = c.id
JOIN inventory i ON o.item_id = i.item_id
JOIN shipping_status s ON o.order_id = s.order_id
WHERE o.order_date >= '2026-01-01'
GROUP BY c.region_id;
