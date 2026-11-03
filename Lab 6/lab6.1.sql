       --------- PART 1 --------
       -------------------------
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

       -------- STEP 1.1 ----------
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(50),
 dept_id INT,
 salary DECIMAL(10, 2)
);

CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);

CREATE TABLE projects (
 project_id INT PRIMARY KEY,
 project_name VARCHAR(50),
 dept_id INT,
 budget DECIMAL(10, 2)
);

     ----------- STEP 1.2 ----------

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
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

INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);


                 --------- PART 2 --------
                 -------------------------

                 --------- STEP 2.1 ----------

SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;
--
  -- Answer: N x M = 5 x 4 = 20 rows. --
--

                 --------- STEP 2.2 ----------

-- a)
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- b)
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;
/*
  Both queries return the same 20 rows as CROSS JOIN:
  comma notation is the old implicit Cartesian product syntax,
  and ON TRUE makes every pair of rows match.
*/

           ---------- STEP 2.3 ----------

SELECT e.emp_name, p.project_name, 'Available' AS status
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
/*
  Result: 5 employees x 5 projects = 25 rows.
  Every employee is paired with every project.
*/

--------- PART 3 --------
                 -------------------------

           ---------- STEP 3.1 ----------

SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
/*
  Result: 4 rows (John, Jane, Mike, Sarah).
  Tom Brown is not included because his dept_id is NULL.
  NULL = 101 (or any value) is not TRUE, it is UNKNOWN,
  so the join condition never matches and INNER JOIN drops the row.
*/

           ---------- STEP 3.2 ----------

SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
/*
  Result: the same 4 rows.
  Difference: with ON the result has two columns e.dept_id and d.dept_id;
  with USING both are merged into ONE dept_id column.
  With SELECT * the ON version shows dept_id twice,
  the USING version shows it once (and first).
*/

           ---------- STEP 3.3 ----------

SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;
/*
  Result: the same 4 rows.
  NATURAL JOIN joins on all columns with the same name -
  here the only common column is dept_id, so it equals USING (dept_id).
*/

           ---------- STEP 3.4 ----------

SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;
/*
  Result: 6 rows.
  IT has 2 employees and 2 projects -> 2 x 2 = 4 rows,
  HR -> 1 row, Finance -> 1 row.
  Tom Brown (no department) and AI Research (no department) are excluded,
  Marketing is excluded (no employees and no projects).
*/


                 --------- PART 4 --------
                 -------------------------

           ---------- STEP 4.1 ----------

SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
/*
  Result: 5 rows - all employees.
  Tom Brown is shown with emp_dept = NULL, dept_dept = NULL, dept_name = NULL,
  because there is no matching department on the right side.
*/

           ---------- STEP 4.2 ----------

SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);
/*
  Result: the same 5 rows, but only one dept_id column.
  Tom Brown: dept_id = NULL, dept_name = NULL.
*/

           ---------- STEP 4.3 ----------

SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
/*
  Result: 1 row - Tom Brown.
  LEFT JOIN keeps all employees, WHERE d.dept_id IS NULL
  leaves only those without a matching department.
*/

           ---------- STEP 4.4 ----------

SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
/*
  Result: IT - 2, HR - 1, Finance - 1, Marketing - 0.
  COUNT(e.emp_id) is used instead of COUNT(*):
  COUNT(*) would count the NULL row of Marketing as 1,
  COUNT(e.emp_id) ignores NULL and gives 0.
*/


                 --------- PART 5 --------
                 -------------------------

           ---------- STEP 5.1 ----------

SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;
/*
  Result: 5 rows - all departments.
  Marketing has emp_name = NULL (no employees).
  Tom Brown is not shown because he has no department.
*/

           ---------- STEP 5.2 ----------

SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;
/*
  Same 5 rows as 5.1.
  A RIGHT JOIN B = B LEFT JOIN A (only the table order is swapped).
*/

           ---------- STEP 5.3 ----------

SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
/*
  Result: 1 row - Marketing, Building D.
*/


                 --------- PART 6 --------
                 -------------------------

           ---------- STEP 6.1 ----------

SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
/*
  Result: 6 rows (4 matched + 1 + 1).
  NULL on the left side (employee columns): Marketing - no employees.
  NULL on the right side (department columns): Tom Brown - no department.
*/

           ---------- STEP 6.2 ----------

SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
/*
  Result: 6 rows.
  IT - Website Redesign, IT - Cloud Migration,
  HR - Employee Training, Finance - Budget Analysis,
  Marketing - NULL (department without projects),
  NULL - AI Research (project without department).
*/

           ---------- STEP 6.3 ----------

SELECT
 CASE
   WHEN e.emp_id IS NULL THEN 'Department without employees'
   WHEN d.dept_id IS NULL THEN 'Employee without department'
   ELSE 'Matched'
 END AS record_status,
 e.emp_name,
 d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;
/*
  Result: 2 rows.
  'Employee without department'  - Tom Brown, NULL
  'Department without employees' - NULL, Marketing
*/


                 --------- PART 7 --------
                 -------------------------

           ---------- STEP 7.1 ----------

-- Query 1: filter in ON clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
/*
  Result: 5 rows - all employees.
  John Smith and Mike Johnson -> IT,
  Jane Doe, Sarah Williams, Tom Brown -> dept_name = NULL.
*/

           ---------- STEP 7.2 ----------

-- Query 2: filter in WHERE clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
/*
  Result: 2 rows - John Smith (IT), Mike Johnson (IT).

  Difference:
  Query 1: the condition is part of the join. It only decides which
  departments are matched; LEFT JOIN still keeps every employee,
  unmatched ones get NULL in department columns.
  Query 2: the filter is applied AFTER the join to the result.
  For employees outside Building A, d.location is a real other value
  or NULL, the condition is not TRUE, so these rows are removed.
  The LEFT JOIN effectively becomes an INNER JOIN.
*/

           ---------- STEP 7.3 ----------

-- Filter in ON clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- Filter in WHERE clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
/*
  Both queries return the same 2 rows: John Smith, Mike Johnson.
  No difference: INNER JOIN keeps only rows where the whole condition is TRUE,
  it does not add NULL rows for unmatched records.
  So it does not matter if the condition is checked in ON or in WHERE.
*/


                 --------- PART 8 --------
                 -------------------------

           ---------- STEP 8.1 ----------

SELECT
 d.dept_name,
 e.emp_name,
 e.salary,
 p.project_name,
 p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
/*
  Result: 7 rows.
  Finance: Sarah x Budget Analysis = 1 row
  HR: Jane x Employee Training = 1 row
  IT: (John, Mike) x (Website Redesign, Cloud Migration) = 4 rows
  Marketing: NULL employee, NULL project = 1 row
  Note: employees and projects of the same department are multiplied.
*/

           ---------- STEP 8.2 ----------

ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT
 e.emp_name AS employee,
 m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
/*
  Result: 5 rows.
  John, Jane, Sarah, Tom -> manager Mike Johnson,
  Mike Johnson -> NULL (he has no manager).
  LEFT JOIN is used so that Mike is not lost.
*/

           ---------- STEP 8.3 ----------

-- Version 1: GROUP BY + HAVING
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

-- Version 2: JOIN with subquery
SELECT d.dept_name, s.avg_salary
FROM departments d
INNER JOIN (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
) s ON d.dept_id = s.dept_id
WHERE s.avg_salary > 50000;
/*
  Result: 3 rows.
  IT - 52500, HR - 60000, Finance - 65000.
  Marketing has no employees, so it is not in the result.
*/


              --------- LAB QUESTIONS --------
              -------------------------------
/*
1. INNER JOIN returns only rows that have a match in both tables.
   LEFT JOIN returns all rows from the left table; if there is no match,
   columns of the right table are NULL.

2. CROSS JOIN is used when all combinations are needed:
   availability matrix (employees x projects), schedules (groups x time slots),
   product variants (sizes x colors), generating test data.

3. In an outer join, the ON condition only controls matching - rows of the
   preserved table are kept anyway, with NULLs. WHERE is applied after the join
   and removes rows, including those NULL rows. In an inner join there are
   no added NULL rows: a row stays only if all conditions are TRUE,
   so ON and WHERE give the same result.

4. 5 x 10 = 50.

5. NATURAL JOIN joins on all columns that have the same name in both tables
   (an equality condition for each of them).

6. Risks of NATURAL JOIN:
   - if a column with the same name is added later (for example created_at,
     name, id), it is automatically added to the join condition and the query
     silently returns wrong results;
   - the join condition is not visible in the query, it is harder to read;
   - columns with the same name but different meaning may be joined;
   - if there are no common columns, it becomes a CROSS JOIN.

7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
   (with SELECT * the column order will be B columns first, then A).

8. FULL OUTER JOIN is used when unmatched rows from BOTH tables are needed:
   comparing / synchronizing two data sets, finding orphaned records
   on both sides at once, data reconciliation reports.
*/


         --------- ADDITIONAL CHALLENGES --------
         ---------------------------------------

           ---------- CHALLENGE 1 ----------
-- FULL OUTER JOIN using LEFT JOIN + RIGHT JOIN

SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION ALL
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
/*
  The second part takes only unmatched departments,
  so matched rows are not duplicated. Result: 6 rows, the same as 6.1.
*/

           ---------- CHALLENGE 2 ----------
-- Employees in departments with more than one project

SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.dept_id IN (
  SELECT dept_id
  FROM projects
  GROUP BY dept_id
  HAVING COUNT(*) > 1
);
/*
  Result: John Smith, Mike Johnson (IT has 2 projects).
*/

           ---------- CHALLENGE 3 ----------
-- Organizational structure

-- Version 1: self-joins (employee -> manager -> manager's manager)
SELECT
 e.emp_name  AS employee,
 m1.emp_name AS manager,
 m2.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id;

-- Version 2: recursive query (any number of levels)
WITH RECURSIVE org AS (
  SELECT emp_id, emp_name, manager_id, 1 AS level,
         CAST(emp_name AS VARCHAR(500)) AS path
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.emp_id, e.emp_name, e.manager_id, o.level + 1,
         CAST(o.path || ' -> ' || e.emp_name AS VARCHAR(500))
  FROM employees e
  INNER JOIN org o ON e.manager_id = o.emp_id
)
SELECT level, emp_name, path
FROM org
ORDER BY path;
/*
  Level 1: Mike Johnson
  Level 2: John Smith, Jane Doe, Sarah Williams, Tom Brown
*/

           ---------- CHALLENGE 4 ----------
-- Pairs of employees in the same department

SELECT a.emp_name AS employee_1, b.emp_name AS employee_2, d.dept_name
FROM employees a
INNER JOIN employees b ON a.dept_id = b.dept_id AND a.emp_id < b.emp_id
INNER JOIN departments d ON a.dept_id = d.dept_id;
/*
  Result: John Smith - Mike Johnson (IT).
  a.emp_id < b.emp_id removes pairs with itself and mirrored duplicates.
*/
