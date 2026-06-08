--CURRENT_WEEK_ARCHIVE_REPORT
CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.CURRENT_WEEK_ARCHIVE_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
     FROM ihg-dart-edw-dev2.DB_SRCD2.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.CURRENT_WEEK_ARCHIVE_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.CURRENT_WEEK_ARCHIVE_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.CURRENT_WEEK_ARCHIVE_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.CURRENT_WEEK_ARCHIVE_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );


---NEXT_WEEK_ARCHIVE_REPORT
CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.NEXT_WEEK_ARCHIVE_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.NEXT_WEEK_ARCHIVE_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.NEXT_WEEK_ARCHIVE_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.NEXT_WEEK_ARCHIVE_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.NEXT_WEEK_ARCHIVE_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );

--CURRENT_WEEK_PURGING_REPORT

CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.CURRENT_WEEK_PURGING_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.CURRENT_WEEK_PURGING_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.CURRENT_WEEK_PURGING_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.CURRENT_WEEK_PURGING_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.CURRENT_WEEK_PURGING_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.CURRENT_WEEK_PURGING_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ARCHV_FILE_SIZE_VAL DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.CURRENT_WEEK_PURGING_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );

-----NEXT_WEEK_PURGING_REPORT
CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.NEXT_WEEK_PURGING_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.NEXT_WEEK_PURGING_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.NEXT_WEEK_PURGING_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.NEXT_WEEK_PURGING_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.NEXT_WEEK_PURGING_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.NEXT_WEEK_PURGING_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.NEXT_WEEK_PURGING_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.NEXT_WEEK_PURGING_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.NEXT_WEEK_PURGING_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.NEXT_WEEK_PURGING_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.NEXT_WEEK_PURGING_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.NEXT_WEEK_PURGING_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.NEXT_WEEK_PURGING_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );



--NO_RULE_MATCH_REPORT
CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.NO_RULE_MATCH_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.NO_RULE_MATCH_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.NO_RULE_MATCH_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.NO_RULE_MATCH_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.NO_RULE_MATCH_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.NO_RULE_MATCH_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.NO_RULE_MATCH_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.NO_RULE_MATCH_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.NO_RULE_MATCH_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.NO_RULE_MATCH_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.NO_RULE_MATCH_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.NO_RULE_MATCH_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.NO_RULE_MATCH_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );


---ARCHIVAL_SIZE_REPORT

CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.ARCHIVAL_SIZE_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.ARCHIVAL_SIZE_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.ARCHIVAL_SIZE_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.ARCHIVAL_SIZE_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.ARCHIVAL_SIZE_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.ARCHIVAL_SIZE_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.ARCHIVAL_SIZE_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.ARCHIVAL_SIZE_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.ARCHIVAL_SIZE_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.ARCHIVAL_SIZE_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.ARCHIVAL_SIZE_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.ARCHIVAL_SIZE_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY FILE_SIZE_IN_MB DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.ARCHIVAL_SIZE_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );


--HOME_FOLDER_REPORT
CREATE OR REPLACE TABLE ihg-dart-edw-qa.DB_SRCQ1.HOME_FOLDER_REPORT_NON_PROD AS (Select * FROM (WITH ranked_dev2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-dev2.DB_SRCD2.HOME_FOLDER_REPORT
),
 ranked_dev AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-dev.DB_SRCD1.HOME_FOLDER_REPORT
),
 ranked_test1 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test1.DB_SRCT1.HOME_FOLDER_REPORT
),
 ranked_test2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test2.DB_SRCT2.HOME_FOLDER_REPORT
),
 ranked_test3 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test3.DB_SRCT3.HOME_FOLDER_REPORT
),
ranked_test4 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test4.DB_SRCT4.HOME_FOLDER_REPORT
),
 ranked_test5 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test5.DB_SRCT5.HOME_FOLDER_REPORT
),
 ranked_test6 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test6.DB_SRCT6.HOME_FOLDER_REPORT
),
 ranked_test7 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test7.DB_SRCT7.HOME_FOLDER_REPORT
),
 ranked_test8 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-test8.DB_SRCT8.HOME_FOLDER_REPORT
),
ranked_qa AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-qa.DB_SRCQ1.HOME_FOLDER_REPORT
),
 ranked_qa2 AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY HOME_FOLDER_SIZE DESC ) AS rank
    FROM ihg-dart-edw-qa2.DB_SRCQA2.HOME_FOLDER_REPORT
)

SELECT * FROM ranked_dev2
UNION ALL
SELECT * FROM ranked_dev
UNION ALL
SELECT * FROM ranked_test1
UNION ALL
SELECT * FROM ranked_test2
UNION ALL
SELECT * FROM ranked_test3
UNION ALL
SELECT * FROM ranked_test4
UNION ALL
SELECT * FROM ranked_test5
UNION ALL
SELECT * FROM ranked_test6
UNION ALL
SELECT * FROM ranked_test7
UNION ALL
SELECT * FROM ranked_test8
UNION ALL
SELECT * FROM ranked_qa
UNION ALL
SELECT * FROM ranked_qa2 ) );

