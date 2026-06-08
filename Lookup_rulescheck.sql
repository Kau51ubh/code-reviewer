--FILE_ARCHV_PVS_WK_IND is to flag files for next week reporting
--Include in run is used to ignore files reported last week
TRUNCATE TABLE ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL;

INSERT INTO  ${SRC_DB}.ETL_SYS_FILE_ARCHV_CUR_WK_DTL
SELECT DISTINCT * FROM (WITH extracted_folders AS (
    SELECT
        d.FILE_NM,
         CASE
    WHEN REGEXP_CONTAINS(cast(d.FILE_LAST_UPDATE_DT as STRING), r'^\d{4}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2}$') THEN
      REGEXP_REPLACE(CAST(d.FILE_LAST_UPDATE_DT AS STRING),
                     r'-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-',
                     CASE
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Jan-%' THEN '-01-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Feb-%' THEN '-02-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Mar-%' THEN '-03-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Apr-%' THEN '-04-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-May-%' THEN '-05-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Jun-%' THEN '-06-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Jul-%' THEN '-07-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Aug-%' THEN '-08-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Sep-%' THEN '-09-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Oct-%' THEN '-10-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Nov-%' THEN '-11-'
                       WHEN cast(d.FILE_LAST_UPDATE_DT as STRING) LIKE '%-Dec-%' THEN '-12-'
                     END)
    WHEN REGEXP_CONTAINS(CAST(d.FILE_LAST_UPDATE_DT AS STRING), r'^\d{4}-\d{2}-\d{2}$') THEN
      CAST(d.FILE_LAST_UPDATE_DT AS STRING)  -- Keep as is for YYYY-MM-DD format
    ELSE NULL  -- Handle unexpected formats
  END AS FILE_LAST_UPDATE_DT,
        d.FILE_OWN_NM,
        d.FILE_SRC_SYS_NM,
        d.FILE_NM AS full_path,
        d.FILE_SIZE_VAL,
        ARRAY_REVERSE(SPLIT(d.FILE_NM, '/'))[SAFE_OFFSET(1)] AS extracted_folder,
        REGEXP_EXTRACT(d.FILE_NM,r'^(.*\/)') AS full_path_without_filename
 FROM
        ${SRC_DB}.ETL_SYS_FILE_ARCHV_DTL d WHERE  DATE(d.LAST_UPDT_TS)= '${PARAM3}'
),
arch_directory_files_custom AS (
    SELECT
        ef.FILE_NM, 
        ef.FILE_SRC_SYS_NM, 
        ef.FILE_LAST_UPDATE_DT, 
        ef.FILE_OWN_NM, 
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
         ef.FILE_SIZE_VAL, 
        CAST(NULL AS DATE)  AS FILE_ARCHV_PLN_DT,
        'NA' AS FILE_SIZE_DSC,
        -- Apply purge logic for arch_directory based on PURGE_RETN_DAYS_CNT
        DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.PURGE_RETN_DAYS_CNT AS INT64) DAY) AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        1 AS PRIORITY_RULE
    FROM extracted_folders ef
    JOIN ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r
        ON LOWER(ef.full_path_without_filename)= LOWER(r.FILE_FOLDER_NM) AND upper(ef.FILE_SRC_SYS_NM) = upper(r.FILE_SRC_SYS_NM)
    WHERE ef.FILE_NM like '%ihg-dart-edw-${PARAM2}-archive%'
),

arch_directory_files AS (
    SELECT
        ef.FILE_NM, 
        ef.FILE_SRC_SYS_NM, 
        ef.FILE_LAST_UPDATE_DT, 
        ef.FILE_OWN_NM, 
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
         ef.FILE_SIZE_VAL, 
        CAST(NULL AS DATE)  AS FILE_ARCHV_PLN_DT,
        'NA' AS FILE_SIZE_DSC,
        -- Apply purge logic for arch_directory based on PURGE_RETN_DAYS_CNT
        DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.PURGE_RETN_DAYS_CNT AS INT64) DAY) AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        2 AS PRIORITY_RULE
    FROM extracted_folders ef
    JOIN ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r
        ON LOWER(ef.extracted_folder) = LOWER(r.FILE_FOLDER_NM) AND upper(ef.FILE_SRC_SYS_NM) = upper(r.FILE_SRC_SYS_NM)
    WHERE ef.FILE_NM like '%ihg-dart-edw-${PARAM2}-archive%'
),

 full_path_rule AS (

    SELECT
	ef.FILE_NM,
        ef.FILE_SRC_SYS_NM,
        ef.FILE_LAST_UPDATE_DT,
        ef.FILE_OWN_NM,
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
        ef.FILE_SIZE_VAL,      
        CASE
            WHEN r.ARCHV_IND = 'N' THEN  '9999-12-31'
            ELSE DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.ARCHV_RETN_DAYS_CNT AS INT64) DAY)
        
        END AS FILE_ARCHV_PLN_DT,
       
        CASE WHEN  r.FILE_SIZE_VAL = 0 THEN 'N'
            WHEN  CAST( ef.FILE_SIZE_VAL AS NUMERIC) > r.FILE_SIZE_VAL  THEN 'Y'
            ELSE 'N'
        END AS FILE_SIZE_DSC,
        CAST(NULL AS DATE)  AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        3 AS PRIORITY_RULE
    FROM
        extracted_folders ef
    JOIN
        ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r 
    ON
    LOWER(ef.full_path_without_filename)=LOWER(r.FILE_FOLDER_NM) 
    WHERE ef.FILE_NM NOT LIKE '%ihg-dart-edw-${PARAM2}-archive%' AND NOT REGEXP_CONTAINS(ef.FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)") AND NOT (REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') AND  REGEXP_CONTAINS(ef.full_path, r'(/stg/|/temp/|/extract/|/manual/)'))
 ),
matched_rules AS (
    SELECT
        ef.FILE_NM,
        ef.FILE_SRC_SYS_NM,
        ef.FILE_LAST_UPDATE_DT,
        ef.FILE_OWN_NM,
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
        ef.FILE_SIZE_VAL,      
         CASE
        
            WHEN r.ARCHV_IND = 'N' THEN  '9999-12-31'
            ELSE DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.ARCHV_RETN_DAYS_CNT AS INT64) DAY)
        
        END AS FILE_ARCHV_PLN_DT,
       
        CASE WHEN  r.FILE_SIZE_VAL = 0 THEN 'N'
            WHEN  ef.FILE_SIZE_VAL > r.FILE_SIZE_VAL  THEN 'Y'
            ELSE 'N'
        END AS FILE_SIZE_DSC,
        CAST(NULL AS DATE)  AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        4 AS PRIORITY_RULE
    FROM
        extracted_folders ef
    JOIN
        ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r
    ON
        upper(ef.FILE_SRC_SYS_NM) = upper(r.FILE_SRC_SYS_NM)
        AND upper(ef.full_path) LIKE CONCAT('%/', upper(r.FILE_FOLDER_NM), '/%')
        AND upper(r.FILE_FOLDER_NM) = upper(ef.extracted_folder)
    WHERE
         /*r.ARCHV_IND= 'Y' AND  */
         NOT (REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') AND  REGEXP_CONTAINS(ef.full_path, r'(/stg/|/temp/|/extract/|/manual/)'))  AND ef.FILE_NM NOT LIKE '%ihg-dart-edw-${PARAM2}-archive%' AND NOT REGEXP_CONTAINS(ef.FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)")
),

parent_rules AS (
    SELECT
        ef.FILE_NM,
        ef.FILE_SRC_SYS_NM,
        ef.FILE_LAST_UPDATE_DT,
        ef.FILE_OWN_NM,
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
        ef.FILE_SIZE_VAL,      
       
         CASE
        
            WHEN r.ARCHV_IND = 'N' THEN  '9999-12-31'
            ELSE DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.ARCHV_RETN_DAYS_CNT AS INT64) DAY)
        
        END AS FILE_ARCHV_PLN_DT,
        CASE WHEN  r.FILE_SIZE_VAL = 0 THEN 'N'
            WHEN ef.FILE_SIZE_VAL  > r.FILE_SIZE_VAL THEN 'Y'
            ELSE 'N'
        END AS FILE_SIZE_DSC  ,
        CAST(NULL AS DATE)  AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        5 AS PRIORITY_RULE
    FROM
        extracted_folders ef
    JOIN
        ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r
    ON
        upper(ef.FILE_SRC_SYS_NM) = upper(r.FILE_SRC_SYS_NM)
        AND upper(ef.full_path) LIKE CONCAT('%/', upper(r.FILE_FOLDER_NM), '/%')
        AND upper(r.FILE_FOLDER_NM) != upper(ef.extracted_folder)
    WHERE 
     /*r.ARCHV_IND= 'Y' AND */
    NOT (REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') AND  REGEXP_CONTAINS(ef.full_path, r'(/stg/|/temp/|/extract/|/manual/)')) AND ef.FILE_NM NOT LIKE '%ihg-dart-edw-${PARAM2}-archive%' AND NOT REGEXP_CONTAINS(ef.FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)")
),
 
predefined_rule AS (
    SELECT
        ef.FILE_NM,
        ef.FILE_SRC_SYS_NM,
        ef.FILE_LAST_UPDATE_DT,
        ef.FILE_OWN_NM,
        r.FILE_FOLDER_NM AS ARCHIVE_RULE_FOLDER,
        r.ARCHV_RETN_DAYS_CNT,
        r.PURGE_RETN_DAYS_CNT,
        ef.FILE_SIZE_VAL,
         CASE
        
            WHEN r.ARCHV_IND = 'N' THEN  '9999-12-31'
            ELSE DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(r.ARCHV_RETN_DAYS_CNT AS INT64) DAY)
        
        END AS FILE_ARCHV_PLN_DT,
          CASE WHEN  r.FILE_SIZE_VAL = 0 THEN 'N'
            WHEN ef.FILE_SIZE_VAL  > r.FILE_SIZE_VAL THEN 'Y'
            ELSE 'N'
        END AS FILE_SIZE_DSC,
        CAST(NULL AS DATE)  AS FILE_PURGE_PLN_DT,
        r.ARCHV_RULE_NO,
        6 AS PRIORITY_RULE 
    FROM
        extracted_folders ef
    JOIN
        ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA r
    ON
         upper(ef.FILE_SRC_SYS_NM) = upper(r.FILE_SRC_SYS_NM) AND
        UPPER(ef.extracted_folder) LIKE CONCAT('%/', UPPER(r.FILE_FOLDER_NM), '/%')
    WHERE 
    /*r.ARCHV_IND= 'Y' AND */
          NOT (REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') AND  REGEXP_CONTAINS(ef.full_path, r'(/stg/|/temp/|/extract/|/manual/)')) 
        AND NOT EXISTS (
            SELECT 1
            FROM MATCHED_RULES mr
            WHERE upper(ef.FILE_NM) = upper(mr.FILE_NM)
        )
        AND NOT EXISTS (
            SELECT 1
            FROM parent_rules pr
            WHERE upper(ef.FILE_NM) = upper(pr.FILE_NM)  
        ) AND ef.FILE_NM NOT LIKE '%ihg-dart-edw-${PARAM2}-archive%' AND NOT REGEXP_CONTAINS(ef.FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)")
),
no_match_report AS (
    SELECT
        IFNULL(ef.FILE_NM, 'NA'),
        IFNULL(ef.FILE_SRC_SYS_NM, 'NA'),
        ef.FILE_LAST_UPDATE_DT,
        IFNULL(ef.FILE_OWN_NM, 'NA'),
        IFNULL(ef.extracted_folder ,'NA') AS ARCHIVE_RULE_FOLDER,  
        default_values.ARCHV_RETN_DAYS_CNT AS ARCHV_RETN_DAYS_CNT,
        NULL AS PURGE_RETN_DAYS_CNT,
        ef.FILE_SIZE_VAL   ,
        CASE
        
            WHEN default_values.ARCHV_IND = 'N' THEN  '9999-12-31'
            ELSE DATE_ADD(CAST(ef.FILE_LAST_UPDATE_DT AS DATE), INTERVAL CAST(default_values.ARCHV_RETN_DAYS_CNT AS INT64) DAY)
        
        END AS FILE_ARCHV_PLN_DT,
        --CAST('9999-12-31' AS DATE) AS FILE_ARCHV_PLN_DT ,
        --CASE WHEN (REGEXP_CONTAINS(ef.extracted_folder, r'(stg|script|extract)$')  AND  REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') ) THEN 'N' ELSE 
        'NRM'  AS FILE_SIZE_DSC,
        CAST(NULL AS DATE)  AS FILE_PURGE_PLN_DT,
        default_values.ARCHV_RULE_NO AS ARCHV_RULE_NO,
         7 AS PRIORITY_RULE
    FROM
        extracted_folders ef
    LEFT JOIN MATCHED_RULES mr
    ON upper(ef.FILE_NM) = upper(mr.FILE_NM)
    LEFT JOIN parent_rules pr
    ON upper(ef.FILE_NM) = upper(pr.FILE_NM)
    LEFT JOIN predefined_rule prd
    ON upper(ef.FILE_NM) = upper(prd.FILE_NM)
    LEFT JOIN full_path_rule fpr
    ON upper(ef.FILE_NM) = upper(fpr.FILE_NM)
    CROSS JOIN (SELECT
      FILE_SIZE_VAL AS FILE_SIZE_VAL,
      ARCHV_RETN_DAYS_CNT AS ARCHV_RETN_DAYS_CNT,
      ARCHV_RULE_NO AS ARCHV_RULE_NO,
      ARCHV_IND AS ARCHV_IND
    FROM
      ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA
    WHERE 
      UPPER(FILE_FOLDER_NM) = 'NRM' ) AS default_values 
    WHERE ef.FILE_SIZE_VAL  > default_values.FILE_SIZE_VAL AND mr.FILE_NM IS NULL
    AND pr.FILE_NM IS NULL AND fpr.FILE_NM IS NULL
    AND prd.FILE_NM IS NULL AND NOT (REGEXP_CONTAINS(ef.FILE_NM, r'(?i)\.(${PARAM5})\b') AND  REGEXP_CONTAINS(ef.full_path, r'(/stg/|/temp/|/extract/|/manual/)')) AND ef.FILE_NM NOT LIKE '%ihg-dart-edw-${PARAM2}-archive%' AND NOT REGEXP_CONTAINS(ef.FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)")) ,

files_with_prv_week AS (
 SELECT  a.FILE_NM,
 a.FILE_SRC_SYS_NM,
   a. FILE_LAST_UPDATE_DT,
    a.FILE_OWN_NM,
    a.FILE_SIZE_VAL,
    a.ARCHIVE_RULE_FOLDER AS FILE_FOLDER_NM,
    a.ARCHV_RETN_DAYS_CNT,
    a.FILE_ARCHV_PLN_DT,
    a.PURGE_RETN_DAYS_CNT,
     a.FILE_PURGE_PLN_DT,
    a.FILE_SIZE_DSC,
    a.ARCHV_RULE_NO,
    a,PRIORITY_RULE,
         CASE
        WHEN LOWER(a.FILE_NM) LIKE '%ihg-dart-edw-${PARAM2}-archive/%' THEN 'N'
        ELSE
        CASE
        WHEN CAST(a.FILE_ARCHV_PLN_DT AS DATE) BETWEEN  CURRENT_DATE()  AND  DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'Y'
        ELSE 'Y'
    END END AS FILE_ARCHV_PVS_WK_IND, 
     CASE
       -- WHEN  ( LOWER(a.FILE_NM) LIKE '%ihg-dart-edw-${PARAM2}-archive/%' AND (CAST(a.FILE_PURGE_PLN_DT AS DATE) BETWEEN  CURRENT_DATE()  AND  DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) )) THEN 'Y'
         WHEN  ( LOWER(a.FILE_NM) LIKE '%ihg-dart-edw-${PARAM2}-archive/%' ) THEN 'Y'
        ELSE 'N'
    END AS FILE_PURGE_PVS_WK_IND,
    CASE 
            WHEN 
				--	(FILE_ARCHV_PVS_WK_IND = 'Y' AND a.FILE_SIZE_DSC = 'Y') 
                -- OR (FILE_PURGE_PVS_WK_IND = 'Y' AND a.FILE_SIZE_DSC = 'Y') 
             (FILE_ARCHV_PVS_WK_IND = 'Y' 
         OR FILE_PURGE_PVS_WK_IND = 'Y' )
                           

            THEN 'N' 
            ELSE 'Y' 
        END AS include_in_run
     FROM (SELECT 
    FILE_NM,
    FILE_SRC_SYS_NM,
    FILE_LAST_UPDATE_DT,
    FILE_OWN_NM,
    FILE_SIZE_VAL,
    ARCHIVE_RULE_FOLDER,
    ARCHV_RETN_DAYS_CNT,
    FILE_ARCHV_PLN_DT,
    PURGE_RETN_DAYS_CNT,
    FILE_PURGE_PLN_DT,
    FILE_SIZE_DSC,
    ARCHV_RULE_NO,
    PRIORITY_RULE

FROM (
    SELECT * FROM arch_directory_files_custom
    UNION ALL
    SELECT * FROM arch_directory_files
    UNION ALL
    SELECT * FROM  full_path_rule
    UNION ALL
    SELECT * FROM MATCHED_RULES
    UNION ALL
    SELECT * FROM parent_rules
    UNION ALL
    SELECT * FROM no_match_report  
    UNION ALL
    SELECT * FROM predefined_rule
)) a

left join ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL prv
on LOWER(a.FILE_NM)= LOWER(prv.FILE_NM)) ,

ranked_rules AS (SELECT fr.*, ROW_NUMBER() OVER (PARTITION BY fr.FILE_NM ORDER BY fr.PRIORITY_RULE ) as rule_rank from files_with_prv_week fr)

SELECT DISTINCT  FILE_NM,
CAST(ARCHV_RULE_NO AS INT64),
  FILE_SRC_SYS_NM,
  FILE_FOLDER_NM,
    FILE_OWN_NM,
    FILE_SIZE_VAL,
      FILE_SIZE_DSC,
     CAST(FILE_LAST_UPDATE_DT AS DATE),
    CASE WHEN FILE_ARCHV_PLN_DT <= '${PARAM3}' THEN '${PARAM3}' ELSE FILE_ARCHV_PLN_DT END AS FILE_ARCHV_PLN_DT,
    CASE WHEN FILE_PURGE_PLN_DT <= '${PARAM3}' THEN '${PARAM3}' ELSE FILE_PURGE_PLN_DT END AS FILE_PURGE_PLN_DT, 
FILE_ARCHV_PVS_WK_IND,
FILE_PURGE_PVS_WK_IND  FROM ranked_rules
WHERE include_in_run='Y'and rule_rank=1
ORDER BY FILE_NM ) WHERE NOT ENDS_WITH (FILE_NM,'/') AND NOT REGEXP_CONTAINS(FILE_NM, r"(empty_igonre|empty_ignore|airflowignore|gitignore)") ;

CREATE OR REPLACE TABLE ${SRC_DB}.ETL_FILES_ACTION_NEEDED AS SELECT DISTINCT
    A.FILE_NM AS PRV_FILENAME,
    B.FILE_NM AS SCAN_FILENAME,
    CASE 
   WHEN A.FILE_NM LIKE '/aedwload/%'THEN CONCAT('ETL_VM', A.FILE_NM)
   WHEN A.FILE_NM LIKE '/aedwextr/%'THEN CONCAT('ETL_VM', A.FILE_NM)
   WHEN A.FILE_NM LIKE 'gs://ihg-dart-edw-${PARAM2}-outbound-common/%' THEN CONCAT(CONCAT('OUTBOUND/', REGEXP_REPLACE(A.FILE_NM, r'gs://[^/]+/', '')),'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME))
   WHEN A.FILE_NM LIKE 'gs://ihg-dart-edw-${PARAM2}-inbound-common/%' THEN CONCAT(CONCAT('INBOUND/', REGEXP_REPLACE(A.FILE_NM, r'gs://[^/]+/', '')),'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME))
   WHEN A.FILE_NM LIKE '${PARAM4}/%' THEN CONCAT(CONCAT('COMPOSER/', REGEXP_REPLACE(A.FILE_NM, r'gs://[^/]+/', '')),'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME))
   WHEN A.FILE_NM LIKE 'gs://ihg-dart-edw-${PARAM2}-staging/%' THEN CONCAT(CONCAT('STAGING/', REGEXP_REPLACE(A.FILE_NM, r'gs://[^/]+/', '')),'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME))
   WHEN  A.FILE_NM LIKE '%gs://ihg-dart-edw-${PARAM2}-archive/%' THEN CONCAT(REGEXP_REPLACE(A.FILE_NM,r'^gs://ihg-dart-edw-${PARAM2}-archive/',''),'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME)) 
   ELSE CONCAT(A.FILE_NM,'_',FORMAT_DATETIME('%Y%d%m%H%M%S', CURRENT_DATETIME))
   END AS ARCHIVED_DIRECTORY,
    A.FILE_LAST_UPDATE_DT AS PRV_FILE_LAST_UPDATE_DT,
    B.FILE_LAST_UPDATE_DT AS SCAN_FILE_LAST_UPDATE_DT,
    A.FILE_SRC_SYS_NM,
    A.FILE_FOLDER_NM,
    A.FILE_OWN_NM,
    A.FILE_SIZE_VAL,
    A.FILE_ARCHV_PLN_DT,
    A.FILE_PURGE_PLN_DT,
    A.FILE_ARCHV_PVS_WK_IND AS ARCHIVE_IND,
    A.FILE_PURGE_PVS_WK_IND AS PURGE_IND,
    A.FILE_SIZE_DSC,
    R.ARCHV_RULE_NO,  -- Adding rule_no from ARCHIVAL_RULE table
    CASE
        WHEN CAST(A.FILE_LAST_UPDATE_DT AS DATE) = B.FILE_LAST_UPDATE_DT THEN 'Action Required'
        ELSE 'No Action Required'
    END AS STATUS
FROM
    ${SRC_DB}.ETL_SYS_FILE_ARCHV_PVS_WK_DTL A
INNER JOIN
    ${SRC_DB}.ETL_SYS_FILE_ARCHV_DTL B
    ON LOWER(A.FILE_NM) = LOWER(B.FILE_NM)
    AND DATE(B.LAST_UPDT_TS)= '${PARAM3}'
INNER JOIN
    ${SRC_DB}.ETL_SYS_FILE_ARCHV_RL_CRTA R
    ON LOWER(A.FILE_FOLDER_NM) = LOWER(R.FILE_FOLDER_NM) AND LOWER(A.FILE_SRC_SYS_NM)=LOWER(R.FILE_SRC_SYS_NM)
    WHERE  R.ARCHV_IND= 'Y' ;
--AND DATE(B.LAST_UPDT_TS)= '${PARAM3}'; 
--A.FILE_SIZE_DSC!='NRM'


