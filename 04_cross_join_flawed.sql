SELECT
    o.*,
    c.*
FROM
    ${AEDW_DB}.orders AS o
INNER JOIN
    ${AEDW_DB}.customers AS c
ON
    o.customer_id = c.customer_id;