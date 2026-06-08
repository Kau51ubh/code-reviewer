-- ============================================================
-- FILE 1: Customer Order Summary Report
-- Schema : DB_AEDWD2
-- ISSUES  : 3 syntax errors + 2 optimization problems
-- ============================================================

-- ERROR 1: Missing backticks around schema.table (BigQuery requires them)
-- ERROR 2: SELECT * used inside a subquery fetching unnecessary columns
-- ERROR 3: GROUP BY references alias 'full_name' which BigQuery doesn't allow in GROUP BY
-- OPT 1  : Repeated subquery on orders can be replaced by a single CTE
-- OPT 2  : UPPER() function on join key prevents partition/index pruning

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)   AS full_name,   -- ERROR 3: aliased below
    c.email,
    c.country,
    c.loyalty_tier,
    order_summary.total_orders,
    order_summary.total_spent,
    order_summary.avg_order_value,
    order_summary.last_order_date

FROM DB_AEDWD2.customers  c                                    -- ERROR 1: missing backticks

-- ERROR 2 + OPT 1: Subquery pulls SELECT * and is not a CTE, runs twice later
LEFT JOIN (
    SELECT *                                                   -- ERROR 2: avoid SELECT *
    FROM `DB_AEDWD2.orders`
    WHERE status != 'CANCELLED'
) raw_orders
    ON UPPER(c.customer_id) = UPPER(raw_orders.customer_id)  -- OPT 2: UPPER() kills pruning

-- OPT 1: Same subquery duplicated instead of referenced from a CTE
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(order_id)          AS total_orders,
        SUM(total_amount)        AS total_spent,
        AVG(total_amount)        AS avg_order_value,
        MAX(order_date)          AS last_order_date
    FROM (
        SELECT *                                               -- ERROR 2 repeated
        FROM `DB_AEDWD2.orders`
        WHERE status != 'CANCELLED'
    )
    GROUP BY customer_id
) order_summary
    ON c.customer_id = order_summary.customer_id

WHERE
    c.is_active = TRUE
    AND c.signup_date >= '2022-01-01'

GROUP BY
    full_name,                                                 -- ERROR 3: alias not allowed
    c.customer_id,
    c.email,
    c.country,
    c.loyalty_tier,
    order_summary.total_orders,
    order_summary.total_spent,
    order_summary.avg_order_value,
    order_summary.last_order_date

ORDER BY
    order_summary.total_spent DESC;
