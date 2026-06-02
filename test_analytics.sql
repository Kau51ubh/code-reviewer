-- Filename: test_analytics.sql
-- Description: Uses advanced analytics clauses to pass local filters

SELECT 
    employee_id,
    department_id,
    salary,
    AVG(salary) OVER (PARTITION BY department_id ORDER BY hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_avg,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) as salary_rank
FROM employee_salary_master
WHERE active_status = 'Y'
GROUP BY department_id, employee_id, salary, hire_date;
