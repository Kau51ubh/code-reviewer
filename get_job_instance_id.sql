SELECT job_instance_id
FROM `{bq_project}`.`{bq_dwh_manage_dataset}`.`job_instances`
WHERE job_identifier = '{final_table}'
  AND source_name = '{src_table}'
  AND partition_id = '{partition_id}'
ORDER BY job_instance_id DESC
LIMIT 1
