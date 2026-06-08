-- ============================================================
-- FILE 5: Customer Lifetime Value (CLV) & Cohort Analysis
-- Schema : DB_AEDWD2
-- ISSUES  : 3 syntax errors + 2 optimization problems
-- ============================================================

-- ERROR 1: INTERVAL syntax wrong for BigQuery — should be INTERVAL 1 YEAR not INTERVAL '1' YEAR
-- ERROR 2: CASE WHEN missing THEN keyword on one branch
-- ERROR 3: Aggregation function SUM() used directly in WHERE clause (not allowed)
-- OPT 1  : Joining on non-key email column instead of customer_id — expensive string match
-- OPT 2  : Scalar subquery for avg_clv runs per row; should be a windowed AVG()

WITH cohort_base AS (

    SELECT
        c.customer_id,
        c.email,
        c.country,
        c.loyalty_tier,
        c.signup_date,

        -- Cohort = year-month of signup
        FORMAT_DATE('%Y-%m', c.signup_date)                   AS cohort_month,

        -- ERROR 1: BigQuery INTERVAL syntax is INTERVAL N unit — not quoted string
        DATE_ADD(c.signup_date, INTERVAL '1' YEAR)            AS first_year_end  -- ERROR 1

    FROM `DB_AEDWD2.customers`  c
    WHERE c.is_active = TRUE

),

order_values AS (

    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.total_amount,
        o.discount_amount,
        (o.total_amount - o.discount_amount)                  AS net_amount,
        o.region,

        -- ERROR 2: CASE WHEN branch missing THEN
        CASE
            WHEN o.total_amount >= 5000  'HIGH'               -- ERROR 2: missing THEN
            WHEN o.total_amount >= 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                   AS order_tier

    FROM `DB_AEDWD2.orders`  o
    WHERE o.status IN ('DELIVERED', 'SHIPPED')

),

clv_calc AS (

    SELECT
        cb.customer_id,
        cb.cohort_month,
        cb.country,
        cb.loyalty_tier,

        COUNT(ov.order_id)                                    AS total_orders,
        SUM(ov.net_amount)                                    AS lifetime_value,
        MIN(ov.order_date)                                    AS first_order_date,
        MAX(ov.order_date)                                    AS last_order_date,
        AVG(ov.net_amount)                                    AS avg_order_value,

        COUNT(CASE WHEN ov.order_tier = 'HIGH'   THEN 1 END) AS high_value_orders,
        COUNT(CASE WHEN ov.order_tier = 'MEDIUM' THEN 1 END) AS medium_value_orders

    -- OPT 1: Joining on email (string) instead of customer_id (indexed key) — very slow
    FROM cohort_base      cb
    JOIN order_values     ov
        ON cb.email = ov.customer_id                          -- OPT 1: wrong & slow join key

    GROUP BY
        cb.customer_id,
        cb.cohort_month,
        cb.country,
        cb.loyalty_tier

)

SELECT
    customer_id,
    cohort_month,
    country,
    loyalty_tier,
    total_orders,
    lifetime_value,
    avg_order_value,
    high_value_orders,
    first_order_date,
    last_order_date,

    -- OPT 2: Scalar correlated subquery for avg CLV — runs once per row; use window instead
    (
        SELECT AVG(lifetime_value)
        FROM clv_calc c2
        WHERE c2.cohort_month = clv_calc.cohort_month
    )                                                         AS cohort_avg_clv,   -- OPT 2

    ROUND(
        lifetime_value / NULLIF(
            (SELECT AVG(lifetime_value)
             FROM clv_calc c3
             WHERE c3.cohort_month = clv_calc.cohort_month)
        , 0) * 100
    , 2)                                                      AS clv_vs_cohort_avg_pct

FROM clv_calc

-- ERROR 3: Aggregate SUM() used directly in WHERE — must use HAVING or outer query
WHERE SUM(lifetime_value) > 500                               -- ERROR 3

ORDER BY
    cohort_month,
    lifetime_value DESC;
