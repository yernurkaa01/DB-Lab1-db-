-- =====================================================================
-- Laboratory Work 8: SQL Indexes (PostgreSQL)
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS lab8;
SET search_path TO lab8;
-- =====================================================================
-- Part 1: Database Setup
-- =====================================================================
DROP VIEW  IF EXISTS index_documentation;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id  INT,
    salary   DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget    DECIMAL(12,2),
    dept_id   INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

-- =====================================================================
-- Part 2: Creating Basic Indexes
-- =====================================================================

-- Exercise 2.1: Simple B-tree index
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8' AND tablename = 'employees';
-- Answer: 2. employees_pkey (postgres made it because of PRIMARY KEY)
--         and emp_salary_idx which I created.

-- Exercise 2.2: Index on a foreign key
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- Answer: postgres doesn't make index on FK by itself. With index on dept_id:
--   - JOIN with departments is faster
--   - WHERE dept_id = 101 is faster
--   - when you delete/update a department, postgres checks employees for this
--     dept_id, without index it goes through the whole table.

-- Exercise 2.3: View index information
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8'
ORDER BY tablename, indexname;
-- Answer: departments_pkey, employees_pkey, projects_pkey - automatic (PK)
--         emp_dept_idx, emp_salary_idx - created by me
--   So automatic ones are the 3 _pkey indexes.

-- =====================================================================
-- Part 3: Multicolumn Indexes
-- =====================================================================

-- Exercise 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- Answer: Not really. Index is sorted by dept_id first and only then by salary
--   inside each dept. So salaries > X are spread all over the index and it can't
--   jump to them. For salary only postgres uses emp_salary_idx.

-- Exercise 3.2: Column order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Answer: Order in WHERE doesn't matter, query 1 and 2 are the same for postgres.
--   But order of columns in the index matters:
--   (dept_id, salary) - first = on dept_id, then range on salary, finds the part
--     quickly. Better for this query.
--   (salary, dept_id) - range on first column, so it reads all salary > 50000
--     and then checks dept_id.
--   Basically columns with = go first, columns with > < go last.

-- =====================================================================
-- Part 4: Unique Indexes
-- =====================================================================

-- Exercise 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com'     WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'       WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'   WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'      WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Test (this INSERT must fail). Wrapped in DO block so the script keeps running.
-- Plain version:
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
DO $$
BEGIN
    INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
    VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END $$;
-- Answer:
--   ERROR:  duplicate key value violates unique constraint "emp_email_unique_idx"
--   DETAIL: Key (email)=(john.smith@company.com) already exists.

-- Exercise 4.2: Unique index vs UNIQUE constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8' AND tablename = 'employees' AND indexname LIKE '%phone%';
-- Answer: Yes, employees_phone_key:
--   CREATE UNIQUE INDEX employees_phone_key ON lab8.employees USING btree (phone)
--   It's a unique B-tree. UNIQUE constraint works through this index.

-- =====================================================================
-- Part 5: Indexes and Sorting
-- =====================================================================

-- Exercise 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- Answer: salaries in the index are already sorted desc, so postgres just reads
--   them in order and doesn't need to sort. Good with LIMIT (top 10 salaries -
--   reads only first 10). Normal ASC index can be read backwards too, so DESC is
--   more useful when sorting several columns in different directions.

-- Exercise 5.2: NULL handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

-- =====================================================================
-- Part 6: Indexes on Expressions
-- =====================================================================

-- Exercise 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Answer: Seq Scan - goes through every row, does LOWER(emp_name) for each one
--   and compares. Normal index on emp_name won't help, it has original names.

-- Exercise 6.2: Index on calculated values
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
-- Result: John Smith (2020-01-15), Sarah Williams (2020-11-05)

-- =====================================================================
-- Part 7: Managing Indexes
-- =====================================================================

-- Exercise 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE schemaname = 'lab8' AND tablename = 'employees';

-- Exercise 7.2
DROP INDEX emp_salary_dept_idx;
-- Answer:
--   - every insert/update/delete also updates all indexes, more indexes = slower writes
--   - they take space
--   - if index isn't used or is a duplicate (like this one) it's just useless

-- Exercise 7.3
REINDEX INDEX employees_salary_index;

-- =====================================================================
-- Part 8: Practical Scenarios
-- =====================================================================

-- Exercise 8.1: Optimize a slow query
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- JOIN:     emp_dept_idx (already created)
-- ORDER BY: emp_salary_desc_idx (already created)

-- Exercise 8.2: Partial index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
-- Answer: it keeps only rows with budget > 80000, so it's smaller and faster, and
--   other rows don't need to update it. But it's used only if query condition fits
--   inside the index condition (budget > 100000 ok, budget > 50000 no).

-- Exercise 8.3: Analyze index usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Output:
--   Seq Scan on employees  (cost=0.00..1.06 rows=2 width=...)
--     Filter: (salary > '52000'::numeric)
-- Answer: Seq Scan. Table has only 5 rows, so reading all of it is cheaper than
--   using the index. Postgres picks what's cheaper, so having an index doesn't mean
--   it will be used. On a big table it uses it (see Challenge 3).

-- =====================================================================
-- Part 9: Index Types Comparison
-- =====================================================================

-- Exercise 9.1: Hash index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Answer: only when you search with = and never need ranges or sorting.
--   Hash can't do > < BETWEEN ORDER BY, can't be unique or multicolumn.
--   So most of the time B-tree is better.

-- Exercise 9.2: B-tree vs Hash
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);

-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';
-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';

-- =====================================================================
-- Part 10: Cleanup and Best Practices
-- =====================================================================

-- Exercise 10.1: Review all indexes and sizes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'lab8'
ORDER BY tablename, indexname;
-- Answer: the hash ones - dept_name_hash_idx and proj_name_hash_idx are 32 kB,
--   all B-tree are 16 kB. Tables are tiny so size is just the minimum structure:
--   hash index has 4 pages from the start (4 x 8 kB), B-tree only 2.

-- Exercise 10.2: Drop unnecessary indexes
DROP INDEX IF EXISTS proj_name_hash_idx;   -- duplicate of proj_name_btree_idx

-- Exercise 10.3: Document indexes
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'lab8'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

-- =====================================================================
-- Additional Challenges (Optional)
-- =====================================================================

-- Challenge 1: find employees hired in a specific month
CREATE INDEX emp_hire_month_idx
    ON employees (EXTRACT(YEAR FROM hire_date), EXTRACT(MONTH FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020
  AND EXTRACT(MONTH FROM hire_date) = 11;
-- (Alternative without expressions: a plain index on hire_date and
--  WHERE hire_date >= '2020-11-01' AND hire_date < '2020-12-01')

-- Challenge 2: composite unique index on (dept_id, email)
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

-- Challenge 3: EXPLAIN ANALYZE with and without an index (on a big table)
DROP TABLE IF EXISTS big_employees;
CREATE TABLE big_employees AS
SELECT g                                  AS emp_id,
       'Employee ' || g                   AS emp_name,
       101 + (g % 3)                      AS dept_id,
       (30000 + random() * 70000)::numeric(10,2) AS salary
FROM generate_series(1, 200000) AS g;
ANALYZE big_employees;

-- Without index -> Seq Scan
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE salary > 99900;

CREATE INDEX big_emp_salary_idx ON big_employees(salary);
ANALYZE big_employees;

-- With index -> Index Scan / Bitmap Index Scan, much faster
EXPLAIN ANALYZE SELECT * FROM big_employees WHERE salary > 99900;

-- Challenge 4: covering index (Index Only Scan)
CREATE INDEX big_emp_dept_cover_idx
    ON big_employees(dept_id) INCLUDE (emp_name, salary);
VACUUM ANALYZE big_employees;

EXPLAIN ANALYZE
SELECT emp_name, salary FROM big_employees WHERE dept_id = 102;
-- With a small enough result the planner can answer from the index only
-- ("Index Only Scan") without reading the table.

EXPLAIN ANALYZE
SELECT emp_id, salary FROM big_employees WHERE salary BETWEEN 50000 AND 50100;
-- big_emp_salary_idx + INCLUDE example:
CREATE INDEX big_emp_salary_cover_idx ON big_employees(salary) INCLUDE (emp_id);
VACUUM ANALYZE big_employees;
EXPLAIN ANALYZE
SELECT emp_id, salary FROM big_employees WHERE salary BETWEEN 50000 AND 50100;



EXPLAIN ANALYZE SELECT * FROM big_employees WHERE salary > 99900;