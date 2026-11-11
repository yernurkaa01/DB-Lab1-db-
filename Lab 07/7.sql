------------------------------------------------
       --  Laboratory Work 7: SQL Views and Roles     --
       ------------------------------------------------



       --------- PART 1: DATABASE SETUP (Lab 6 tables) --------
       ---------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv CASCADE;
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv CASCADE;
DROP TABLE IF EXISTS temp_table CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id  INT,
    salary   DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);


       --------- PART 2: CREATING BASIC VIEWS --------
       -----------------------------------------------

       ---------- EXERCISE 2.1 ----------
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;
/*
  Result: 4 rows (John Smith, Jane Doe, Mike Johnson, Sarah Williams).
  Tom Brown does not appear because his dept_id is NULL.
  The view uses INNER JOIN, and NULL = <any dept_id> is UNKNOWN, not TRUE,
  so his row has no match in departments and is dropped.
*/

       ---------- EXERCISE 2.2 ----------
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;
/*
  Result: 4 rows - all departments.
  IT has 2 employees, HR and Finance have 1.
  Marketing has 0 employees: LEFT JOIN keeps it,
  COUNT(e.emp_id) gives 0, AVG/MAX/MIN give NULL.
*/

       ---------- EXERCISE 2.3 ----------
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       (SELECT COUNT(*)
        FROM employees e
        WHERE e.dept_id = p.dept_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

SELECT * FROM project_overview;
/*
  Result: 5 rows - all projects.
  AI Research has no department, so dept_name/location are NULL
  and team_size = 0.
*/

       ---------- EXERCISE 2.4 ----------
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
/*
  Result: 2 rows - Jane Doe (60000) and Sarah Williams (65000).
  Mike Johnson earns exactly 55000, and the condition is "> 55000",
  so he is not included.
  Yes, we see all high earners here, because both of them have a department.
  But if a high earner had dept_id = NULL, INNER JOIN would hide him.
  The view stores no data - it runs the query every time,
  so it always shows the current data of the table.
*/


       --------- PART 3: MODIFYING AND MANAGING VIEWS --------
       -------------------------------------------------------

       ---------- EXERCISE 3.1 ----------
-- CREATE OR REPLACE can only ADD new columns at the END of the view,
-- so salary_grade goes last.
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

       ---------- EXERCISE 3.2 ----------
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

       ---------- EXERCISE 3.3 ----------
CREATE VIEW temp_view AS
SELECT emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;   -- Tom Brown (45000)

DROP VIEW temp_view;


       --------- PART 4: UPDATABLE VIEWS --------
       ------------------------------------------

       ---------- EXERCISE 4.1 ----------
-- Simple view: one table, no JOIN/GROUP BY/DISTINCT/aggregates,
-- so PostgreSQL makes it updatable automatically.
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

       ---------- EXERCISE 4.2 ----------
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';
/*
  Yes, the underlying table was updated: John Smith now has 52000
  in the employees table. A view stores no data, so the UPDATE
  is passed directly to the base table.
*/

       ---------- EXERCISE 4.3 ----------
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees;
/*
  Yes, the insert was successful - Alice Johnson appears
  in the employees table. The view includes all columns of the table,
  so the new row is fully written into employees.
*/

       ---------- EXERCISE 4.4 ----------
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- This should fail
INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);
/*
  Error:
    ERROR: new row violates check option for view "it_employees"
    DETAIL: Failing row contains (7, Bob Wilson, 103, 60000.00).
  Why: WITH CHECK OPTION does not allow inserting/updating rows
  that the view itself would not show. The view shows only dept_id = 101,
  and Bob has dept_id = 103, so the row is rejected.
  Without CHECK OPTION the insert would succeed, but the row
  would "disappear" from the view.
*/


       --------- PART 5: MATERIALIZED VIEWS --------
       ---------------------------------------------

       ---------- EXERCISE 5.1 ----------
-- Counts are calculated in subqueries: joining employees and projects
-- together would multiply rows (2 employees x 2 projects = 4)
-- and give wrong sums.
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e
        WHERE e.dept_id = d.dept_id) AS total_employees,
       COALESCE((SELECT SUM(e.salary) FROM employees e
                 WHERE e.dept_id = d.dept_id), 0) AS total_salaries,
       (SELECT COUNT(*) FROM projects p
        WHERE p.dept_id = d.dept_id) AS total_projects,
       COALESCE((SELECT SUM(p.budget) FROM projects p
                 WHERE p.dept_id = d.dept_id), 0) AS total_budget
FROM departments d
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

       ---------- EXERCISE 5.2 ----------
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- Before refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- After refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
/*
  Before refresh: IT shows 2 employees, total_salaries = 107000
  (old data - Charlie is not there).
  After refresh: IT shows 3 employees, total_salaries = 161000.
  A materialized view stores the result physically, like a snapshot.
  It does not see changes in the tables until REFRESH runs the query again.
*/

       ---------- EXERCISE 5.3 ----------
CREATE UNIQUE INDEX dept_summary_mv_dept_id_idx
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
/*
  Advantage of CONCURRENTLY: the view is NOT locked for reading
  during the refresh. A normal REFRESH takes an exclusive lock,
  so all SELECTs wait until it finishes. CONCURRENTLY builds
  the new result separately and then applies only the differences,
  so users can keep querying the old data.
  Cost: it is slower and needs a UNIQUE index on the view
  (that is why we created one on dept_id).
*/

       ---------- EXERCISE 5.4 ----------
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e
        WHERE e.dept_id = p.dept_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;

SELECT * FROM project_stats_mv;
/*
  Error:
    ERROR: materialized view "project_stats_mv" has not been populated
    HINT: Use the REFRESH MATERIALIZED VIEW command.
  WITH NO DATA creates only the structure - the query is not executed,
  so the view is empty and cannot be read.
  Fix: fill it with REFRESH (below).
*/

REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


       --------- PART 6: DATABASE ROLES --------
       -----------------------------------------

       ---------- EXERCISE 6.1 ----------
CREATE ROLE analyst;                                  -- NOLOGIN by default
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE USER report_user WITH PASSWORD 'report456';   -- CREATE USER = CREATE ROLE ... LOGIN

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

       ---------- EXERCISE 6.2 ----------
CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager WITH CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin999';

SELECT rolname, rolcanlogin, rolcreatedb, rolcreaterole, rolsuper
FROM pg_roles
WHERE rolname IN ('db_creator', 'user_manager', 'admin_user');

       ---------- EXERCISE 6.3 ----------
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

       ---------- EXERCISE 6.4 ----------
-- 1. Group roles (no login)
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

-- 2. Individual users
CREATE USER hr_user1 WITH PASSWORD 'hr001';
CREATE USER hr_user2 WITH PASSWORD 'hr002';
CREATE USER finance_user1 WITH PASSWORD 'fin001';

-- 3-4. Membership
GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

-- 5-6. Privileges for the groups
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

       ---------- EXERCISE 6.5 ----------
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

       ---------- EXERCISE 6.6 ----------
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

SELECT rolname, rolcanlogin, rolsuper, rolconnlimit
FROM pg_roles
WHERE rolname IN ('analyst', 'user_manager', 'data_viewer');


       --------- PART 7: ADVANCED ROLE MANAGEMENT --------
       ---------------------------------------------------

       ---------- EXERCISE 7.1 ----------
-- 1. Parent role
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- 2. Child roles
CREATE USER junior_analyst WITH PASSWORD 'junior123';
CREATE USER senior_analyst WITH PASSWORD 'senior123';

-- 3. Both inherit read_only
GRANT read_only TO junior_analyst, senior_analyst;

-- 4. Extra rights only for senior
GRANT INSERT, UPDATE ON employees TO senior_analyst;

       ---------- EXERCISE 7.2 ----------
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';
/*
  projects -> project_manager, the other tables -> postgres.
  dept_statistics is a view, so it is not in pg_tables. Check it here:
*/
SELECT viewname, viewowner
FROM pg_views
WHERE schemaname = 'public';

       ---------- EXERCISE 7.3 ----------
-- 1.
CREATE ROLE temp_owner WITH LOGIN;
-- 2.
CREATE TABLE temp_table (id INT);
-- 3.
ALTER TABLE temp_table OWNER TO temp_owner;
-- 4. Give all its objects to postgres (temp_table goes back to postgres)
REASSIGN OWNED BY temp_owner TO postgres;
-- 5. Remove what is left (objects and granted privileges)
DROP OWNED BY temp_owner;
-- 6. Now the role owns nothing and can be dropped
DROP ROLE temp_owner;
/*
  A role cannot be dropped while it owns objects or has privileges
  ("role cannot be dropped because some objects depend on it").
  REASSIGN OWNED + DROP OWNED clean everything, then DROP ROLE works.
*/

       ---------- EXERCISE 7.4 ----------
-- 1-2.
CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

-- 3-4.
CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;
/*
  hr_team sees only HR rows (row restriction),
  finance_team sees all employees but only 3 columns (column restriction).
  They get access to the views, not to the employees table itself.
*/


       --------- PART 8: PRACTICAL SCENARIOS --------
       ----------------------------------------------

       ---------- EXERCISE 8.1 ----------
CREATE VIEW dept_dashboard AS
WITH emp AS (
    SELECT dept_id,
           COUNT(*) AS employee_count,
           AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
),
proj AS (
    SELECT dept_id,
           COUNT(*) AS active_projects,
           SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
)
SELECT d.dept_name,
       d.location,
       COALESCE(emp.employee_count, 0) AS employee_count,
       ROUND(emp.avg_salary, 2) AS avg_salary,
       COALESCE(proj.active_projects, 0) AS active_projects,
       COALESCE(proj.total_budget, 0) AS total_project_budget,
       ROUND(COALESCE(proj.total_budget, 0)
             / NULLIF(emp.employee_count, 0), 2) AS budget_per_employee
FROM departments d
LEFT JOIN emp  ON d.dept_id = emp.dept_id
LEFT JOIN proj ON d.dept_id = proj.dept_id;

SELECT * FROM dept_dashboard;
/*
  NULLIF(employee_count, 0) turns 0 into NULL, and x / NULL = NULL,
  so Marketing (0 employees) gets NULL instead of a division-by-zero error.
*/

       ---------- EXERCISE 8.2 ----------
-- 1.
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2-4.
CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;
/*
  3 rows:
    AI Research       200000 -> Critical Review Required (no department)
    Cloud Migration   150000 -> Management Approval Needed (150000 is not > 150000)
    Website Redesign  100000 -> Standard Process            (100000 is not > 100000)
  Budget Analysis (75000) is not included - the condition is > 75000.
*/

       ---------- EXERCISE 8.3 ----------
-- Level 1 - Viewer
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;  -- tables + views

-- Level 2 - Entry
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3 - Analyst
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4 - Manager
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE USER alice WITH PASSWORD 'alice123';
CREATE USER bob WITH PASSWORD 'bob123';
CREATE USER charlie WITH PASSWORD 'charlie123';

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
/*
  Each level inherits all rights of the level below:
    alice   -> SELECT
    bob     -> SELECT + INSERT + UPDATE
    charlie -> SELECT + INSERT + UPDATE + DELETE
*/

-- Check: who is a member of which role
SELECT r.rolname AS role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname IN ('viewer_role', 'entry_role', 'analyst_role', 'manager_role')
ORDER BY r.rolname;

