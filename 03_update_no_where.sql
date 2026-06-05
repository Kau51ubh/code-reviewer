UPDATE ${AEDW_DB}.orders
SET amount = amount * 1.1,
    etl_batch_sk = ${ETL_BATCH_SK}
WHERE <MISSING_FILTER_REQUIRED> /* TODO: Add specific condition */;