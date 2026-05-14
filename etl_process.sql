select * from employees a, departments b 
where a.dept_id = b.dept_id and a.salary > 
(select avg(salary) from employees)
