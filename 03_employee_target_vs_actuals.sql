-- ============================================================
-- FILE 3: Employee Sales Target vs Actuals
-- Schema : DB_AEDWD2
-- ISSUES  : 3 syntax errors + 2 optimization problems
-- ============================================================

-- ERROR 1: COALESCE used with mismatched types (STRING vs NUMERIC)
-- ERROR 2: Window function ORDER BY uses a column not in scope
-- ERROR 3: JOIN condition uses = instead of ON keyword missing (syntax)
-- OPT 1  : Correlated subquery inside SELECT — should be a JOIN
-- OPT 2  : CAST done inside GROUP BY — redundant and expensive

WITH actuals AS (

    SELECT
        o.region,
        p.category,
        CAST(EXTRACT(YEAR  FROM o.order_date) AS STRING) AS yr,  -- OPT 2: CAST in grouping
        CAST(EXTRACT(QUARTER FROM o.order_date) AS STRING) AS qtr,
        SUM(o.total_amount - o.discount_amount)              AS net_sales
    FROM `DB_AEDWD2.orders`         o
    JOIN `DB_AEDWD2.order_items`    oi  ON o.order_id  = oi.order_id
    JOIN `DB_AEDWD2.products`       p   ON oi.product_id = p.product_id
    WHERE o.status IN ('SHIPPED', 'DELIVERED')
    GROUP BY
        o.region,
        p.category,
        CAST(EXTRACT(YEAR    FROM o.order_date) AS STRING),       -- OPT 2: repeated CAST
        CAST(EXTRACT(QUARTER FROM o.order_date) AS STRING)
),

targets AS (

    SELECT
        st.region,
        st.category,
        CAST(st.target_year    AS STRING)                    AS yr,
        CAST(st.target_quarter AS STRING)                    AS qtr,
        st.target_amount,
        st.assigned_to

    FROM `DB_AEDWD2.sales_targets`  st

),

combined AS (

    SELECT
        t.region,
        t.category,
        t.yr,
        t.qtr,
        t.assigned_to,

        -- ERROR 1: COALESCE mixes STRING ('No Sales') and NUMERIC (a.net_sales)
        COALESCE(a.net_sales, 'No Sales')                    AS actual_sales,

        t.target_amount,
        ROUND(
            (COALESCE(a.net_sales, 0) - t.target_amount)
            / NULLIF(t.target_amount, 0) * 100
        , 2)                                                 AS achievement_pct

    FROM targets   t
    LEFT JOIN actuals  a
        ON  t.region   = a.region
        AND t.category = a.category
        AND t.yr       = a.yr
        AND t.qtr      = a.qtr
)

SELECT
    c.region,
    c.category,
    c.yr,
    c.qtr,
    c.assigned_to,
    e.full_name                                              AS employee_name,
    e.department,
    c.actual_sales,
    c.target_amount,
    c.achievement_pct,

    -- ERROR 2: Window RANK() ordered by 'actual_sales' alias — not valid in BigQuery window
    RANK() OVER (
        PARTITION BY c.region, c.yr, c.qtr
        ORDER BY actual_sales DESC                           -- ERROR 2: alias in OVER clause
    )                                                        AS regional_rank,

    -- OPT 1: Correlated subquery runs once per row — should JOIN employees CTE instead
    (
        SELECT COUNT(*)
        FROM `DB_AEDWD2.orders` o
        WHERE o.region = c.region
          AND EXTRACT(YEAR    FROM o.order_date) = CAST(c.yr  AS INT64)
          AND EXTRACT(QUARTER FROM o.order_date) = CAST(c.qtr AS INT64)
    )                                                        AS region_order_count

-- ERROR 3: Missing ON keyword in JOIN — bare condition written incorrectly
FROM combined c
JOIN `DB_AEDWD2.employees` e
    c.assigned_to = e.employee_id                           -- ERROR 3: missing ON

WHERE
    c.yr  = CAST(EXTRACT(YEAR  FROM CURRENT_DATE()) AS STRING)

ORDER BY
    c.region,
    c.yr,
    c.qtr,
    c.achievement_pct DESC;
