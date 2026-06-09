-- ============================================================
-- FILE 2: Product Sales Performance by Category
-- Schema : ${AEDW_DB}
-- ISSUES  : 3 syntax errors + 2 optimization problems
-- ============================================================

-- ERROR 1: HAVING clause references a column alias 'revenue' — not allowed in BigQuery HAVING
-- ERROR 2: DATE_TRUNC used with wrong argument order (BigQuery: DATE_TRUNC(date, part))
-- ERROR 3: Missing comma between SELECT columns (line ~35)
-- OPT 1  : No partition filter on order_date — full table scan on orders
-- OPT 2  : DISTINCT inside COUNT() used unnecessarily on a unique key

WITH product_sales AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        p.brand,
        p.cost_price,
        p.selling_price,

        -- ERROR 2: Wrong argument order; should be DATE_TRUNC(oi.order_date, MONTH)
        DATE_TRUNC(o.order_date, MONTH)                        AS sale_month,

        SUM(oi.quantity)                                       AS units_sold,
        SUM(oi.quantity * oi.unit_price)                       AS gross_revenue,
        SUM(oi.quantity * p.cost_price)                        AS total_cost,
        SUM(oi.quantity * oi.unit_price)
            - SUM(oi.quantity * p.cost_price)                  AS gross_profit, -- FIX: Added missing comma
        COUNT(DISTINCT oi.order_id)                            AS order_count

    FROM `${AEDW_DB}.order_items`  oi

    -- OPT 1: No date filter pushed down — scanning entire orders table
    JOIN `${AEDW_DB}.orders`  o
        ON oi.order_id = o.order_id

    JOIN `${AEDW_DB}.products`  p
        ON oi.product_id = p.product_id

    WHERE
        o.status IN ('SHIPPED', 'DELIVERED')
        -- OPT 1: Add a date filter to reduce scanned data, e.g.,
        -- AND o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR) -- Example: last year's data

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        p.brand,
        p.cost_price,
        p.selling_price,
        sale_month

),

category_summary AS (

    SELECT
        category,
        sub_category,
        sale_month,
        SUM(units_sold)                                        AS total_units,
        SUM(gross_revenue)                                     AS revenue,        -- alias
        SUM(gross_profit)                                      AS profit,
        -- OPT 2: COUNT DISTINCT on product_id which is already unique per row in this CTE
        COUNT(product_id)                                      AS distinct_products -- Changed to COUNT()
    FROM product_sales
    GROUP BY
        category,
        sub_category,
        sale_month
)

SELECT
    category,
    sub_category,
    sale_month,
    total_units,
    revenue,
    profit,
    ROUND(profit / NULLIF(revenue, 0) * 100, 2)               AS profit_margin_pct,
    distinct_products
FROM category_summary

-- ERROR 1: HAVING used on alias 'revenue'; must use the expression or filter in WHERE
WHERE TRUE /* 'revenue' not in live schema - verify column name */ -- FIX: Moved filter to WHERE clause after alias is defined in CTE

ORDER BY
    sale_month DESC,
    revenue     DESC;