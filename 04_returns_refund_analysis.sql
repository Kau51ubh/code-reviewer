-- ============================================================
-- FILE 4: Returns Analysis & Refund Impact
-- Schema : DB_AEDWD2
-- ISSUES  : 3 syntax errors + 2 optimization problems
-- ============================================================

-- ERROR 1: DATEDIFF not a BigQuery function — should be DATE_DIFF(date1, date2, DAY)
-- ERROR 2: WHERE clause filters on a window function result directly (not allowed)
-- ERROR 3: String literal compared using == instead of =
-- OPT 1  : Non-SARGable filter: CAST on partition column prevents pruning
-- OPT 2  : Redundant ORDER BY inside a CTE (no effect in BigQuery CTEs)

WITH return_details AS (

    SELECT
        r.return_id,
        r.order_id,
        r.item_id,
        r.return_date,
        r.reason,
        r.refund_amount,
        r.approved_by,
        o.customer_id,
        o.order_date,
        o.region,
        o.payment_method,
        p.product_id,
        p.product_name,
        p.category,
        p.brand,

        -- ERROR 1: DATEDIFF is SQL Server syntax; BigQuery uses DATE_DIFF
        DATEDIFF(r.return_date, DATE(o.order_date), DAY)     AS days_to_return,

        oi.unit_price,
        oi.quantity,
        (oi.unit_price * oi.quantity)                        AS item_revenue

    FROM `DB_AEDWD2.returns`        r
    JOIN `DB_AEDWD2.orders`         o   ON r.order_id  = o.order_id

    -- OPT 1: CAST on order_date inside filter prevents partition pruning
    JOIN `DB_AEDWD2.order_items`    oi  ON r.item_id   = oi.item_id
        AND CAST(o.order_date AS DATE) >= '2023-01-01'       -- OPT 1: non-SARGable

    JOIN `DB_AEDWD2.products`       p   ON oi.product_id = p.product_id

    -- ERROR 3: double equals used for string comparison
    WHERE r.reason == 'DEFECTIVE'                            -- ERROR 3: should be =
       OR r.reason == 'WRONG_ITEM'

    -- OPT 2: ORDER BY inside CTE is meaningless in BigQuery
    ORDER BY r.return_date DESC                              -- OPT 2: redundant

),

category_return_stats AS (

    SELECT
        category,
        brand,
        region,
        COUNT(return_id)                                     AS total_returns,
        SUM(refund_amount)                                   AS total_refund,
        AVG(days_to_return)                                  AS avg_days_to_return,
        SUM(item_revenue)                                    AS affected_revenue,
        ROUND(
            SUM(refund_amount) / NULLIF(SUM(item_revenue), 0) * 100
        , 2)                                                 AS refund_rate_pct,

        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY SUM(refund_amount) DESC
        )                                                    AS rank_within_category

    FROM return_details
    GROUP BY
        category,
        brand,
        region

)

SELECT
    category,
    brand,
    region,
    total_returns,
    total_refund,
    avg_days_to_return,
    affected_revenue,
    refund_rate_pct,
    rank_within_category

FROM category_return_stats

-- ERROR 2: Filtering on window function result directly in WHERE — must use outer query
WHERE rank_within_category <= 5                              -- ERROR 2: illegal in same scope

ORDER BY
    category,
    rank_within_category;
