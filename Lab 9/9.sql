-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Setup + parts 2-7, all in one file
-- just run the whole thing at once in one console, it goes through without errors
-- the parts that should give an error (3.4, 4.3, 5.3, 5.4, 6.1, 6.3) go through
-- show_error(), it catches the error and shows the text as a row
-- ============================================================


-- ============================================================
-- Part 0: drop old functions first so I can rerun the script
-- ============================================================
DROP FUNCTION IF EXISTS show_error(TEXT);
DROP FUNCTION IF EXISTS inc(INTEGER);
DROP FUNCTION IF EXISTS rental_days(INT);
DROP FUNCTION IF EXISTS member_rental_count(INT);
DROP FUNCTION IF EXISTS station_city(INT);
DROP FUNCTION IF EXISTS fee_with_discount(NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS member_stats(INT);
DROP FUNCTION IF EXISTS apply_late_fee(NUMERIC);
DROP FUNCTION IF EXISTS fee_summary(NUMERIC[]);
DROP FUNCTION IF EXISTS total_fees(INT);
DROP FUNCTION IF EXISTS total_fees(INT, DATE);
DROP FUNCTION IF EXISTS total_fees(VARCHAR);
DROP FUNCTION IF EXISTS find_bikes(VARCHAR);
DROP FUNCTION IF EXISTS member_history(INT);
DROP FUNCTION IF EXISTS bike_list(INT);
DROP FUNCTION IF EXISTS station_board(VARCHAR);
DROP FUNCTION IF EXISTS fee_split(DATE);
DROP FUNCTION IF EXISTS station_load(INT);
DROP FUNCTION IF EXISTS top_members(INT);
DROP FUNCTION IF EXISTS rental_invoice(INT);
DROP FUNCTION IF EXISTS city_report(VARCHAR);
DROP FUNCTION IF EXISTS city_report(VARCHAR, DATE);


-- ============================================================
-- Part 1: Database Setup (CityBike rental network)
-- ============================================================
DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

-- Step 1.1: Create the tables
CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

-- Step 1.2: Load the sample data
INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

-- check: should be 5 | 8 | 6 | 22
SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;


-- ============================================================
-- helper, not part of the lab
-- runs a query that should fail and shows the error text as a row
-- otherwise the script stops at the first error
-- ============================================================
CREATE OR REPLACE FUNCTION show_error(p_sql TEXT)
RETURNS TABLE (err_sqlstate TEXT, err_message TEXT, err_detail TEXT, err_hint TEXT) AS $$
BEGIN
    EXECUTE p_sql;
    RETURN QUERY SELECT NULL::TEXT, 'no error'::TEXT, NULL::TEXT, NULL::TEXT;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        err_sqlstate = RETURNED_SQLSTATE,
        err_message  = MESSAGE_TEXT,
        err_detail   = PG_EXCEPTION_DETAIL,
        err_hint     = PG_EXCEPTION_HINT;
    RETURN NEXT;
END; $$
LANGUAGE plpgsql;


-- ============================================================
-- Part 2: Your First Function
-- ============================================================

-- Worked example: inc()
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    result := val + 1;
    RETURN result;
END; $$
LANGUAGE plpgsql;

SELECT inc(10);   -- 11


-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
      INTO v_days
      FROM rentals
     WHERE rental_id = p_rental_id;
    RETURN v_days;
END; $$
LANGUAGE plpgsql;

SELECT rental_days(2);     -- 5
SELECT rental_days(11);    -- 8
SELECT rental_days(19);    -- NULL, rental is still open (no end_date)
SELECT rental_days(999);   -- NULL, there is no rental 999


-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_cnt;
END; $$
LANGUAGE plpgsql;

SELECT member_rental_count(1);    -- 5
SELECT member_rental_count(5);    -- 4
SELECT member_rental_count(6);    -- 0
SELECT member_rental_count(99);   -- 0


-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
      INTO v_city
      FROM stations
     WHERE station_id = p_station_id;
    RETURN v_city;
END; $$
LANGUAGE plpgsql;

SELECT station_city(30);   -- Astana
SELECT station_city(77);   -- NULL


-- Exercise 2.4: Using a function inside a query
SELECT rental_id,
       member_id,
       rental_days(rental_id) AS duration
  FROM rentals
 WHERE rental_days(rental_id) > 4
 ORDER BY duration DESC, rental_id;


-- ============================================================
-- Part 3: Parameter Modes
-- ============================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (100 - p_percent) / 100, 2);
END; $$
LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);   -- 62.90


-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id    INT,
    OUT rental_cnt INT,
    OUT total_fee  NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
      INTO rental_cnt, total_fee, last_start
      FROM rentals
     WHERE member_id = p_member_id;
END; $$
LANGUAGE plpgsql;

SELECT member_stats(3);            -- all in one column (5,164.75,2025-06-01)
SELECT * FROM member_stats(3);     -- 3 separate columns
SELECT * FROM member_stats(6);     -- 0 | 0 | NULL


-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$
LANGUAGE plpgsql;

SELECT rental_id, fee, apply_late_fee(fee) AS fee_with_late_charge
  FROM rentals
 WHERE rental_id = 1;              -- 13.50 -> 18.50


-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total   NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
      INTO total, average, largest
      FROM generate_subscripts(p_fees, 1) g(i);
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);   -- 98.50 | 24.63 | 35.00

-- 3.4 question: call with no arguments
SELECT * FROM show_error($q$SELECT * FROM fee_summary()$q$);


-- Exercise 3.5: Choosing a mode
-- (a) id of the row -> IN, we only read it
-- (b) running balance -> INOUT, we get it, change it and give it back
-- (c) list of station ids, don't know how many -> VARIADIC, they go into an array
-- (d) two stats at once -> two OUT params, one call gives both


-- ============================================================
-- Part 4: Default Values and Function Overloading
-- ============================================================

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1);   -- 98.50
SELECT total_fees(6);   -- 0


-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');   -- 98.50
SELECT total_fees(1, DATE '2025-01-01');   -- 50.00

-- show both versions. \df doesn't work in DataGrip so I use pg_proc
SELECT p.oid::regprocedure             AS signature,
       pg_get_function_arguments(p.oid) AS arguments,
       pg_get_function_result(p.oid)    AS returns
  FROM pg_proc p
 WHERE p.proname = 'total_fees'
 ORDER BY p.pronargs;


-- Exercise 4.3: Giving a parameter a default value
-- same args (INT, DATE) so it just replaces the 4.2 one and adds the default
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

-- SELECT total_fees(1) fails here, this is the error and hint:
SELECT * FROM show_error($q$SELECT total_fees(1)$q$);


-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);   -- 50.00, now the 2-param version answers with default date 2025-01-01


-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_full_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
      INTO v_total
      FROM members m
      JOIN rentals r ON r.member_id = m.member_id
     WHERE m.full_name = p_full_name;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');   -- 98.50, varchar version, counts all rentals
SELECT total_fees(1);                   -- 50.00, int version with default date, only from 2025


-- ============================================================
-- Part 5: Functions That Return a Table
-- ============================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT b.bike_id, b.model, b.daily_rate
          FROM bikes b
         WHERE b.model ILIKE p_pattern
         ORDER BY b.bike_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');   -- 105, 108
SELECT * FROM find_bikes('%Mini');    -- 106

-- 5.1 question: without FROM everything comes in one column
SELECT find_bikes('%road%');


-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT,
               h_model     VARCHAR,
               h_station   VARCHAR,
               h_days      INT,
               h_fee       NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT r.rental_id,
               b.model,
               s.station_name,
               r.end_date - r.start_date,
               r.fee
          FROM rentals r
          JOIN bikes    b ON b.bike_id    = r.bike_id
          JOIN stations s ON s.station_id = b.station_id
         WHERE r.member_id = p_member_id
         ORDER BY r.start_date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM member_history(3);


-- Exercise 5.3: When the column names collide
-- original version, CREATE works
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

-- but calling it gives an error:
SELECT * FROM show_error($q$SELECT * FROM bike_list(10)$q$);

-- Fix 1: rename output columns
-- have to drop the old one first, OR REPLACE can't change the return type
DROP FUNCTION bike_list(INT);

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);   -- 101, 102, 108

-- Fix 2: keep the names, use table alias b.
DROP FUNCTION bike_list(INT);

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT b.bike_id, b.model
          FROM bikes b
         WHERE b.station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);   -- 101, 102, 108


-- Exercise 5.4: Casting the output
-- no cast: CREATE works, the call fails
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
        SELECT s.station_name,
               COUNT(b.bike_id),
               s.capacity - COUNT(b.bike_id)
          FROM stations s
          LEFT JOIN bikes b ON b.station_id = s.station_id
         WHERE s.city = p_city
         GROUP BY s.station_id, s.station_name, s.capacity
         ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

-- the error:
SELECT * FROM show_error($q$SELECT * FROM station_board('Almaty')$q$);

-- fixed with ::INT casts, return type is the same so OR REPLACE is fine
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
        SELECT s.station_name,
               COUNT(b.bike_id)::INT,
               (s.capacity - COUNT(b.bike_id))::INT
          FROM stations s
          LEFT JOIN bikes b ON b.station_id = s.station_id
         WHERE s.city = p_city
         GROUP BY s.station_id, s.station_name, s.capacity
         ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');


-- ============================================================
-- Part 6: Block Structure, DO Blocks and Subblocks
-- RAISE NOTICE output is in the Output tab in DataGrip
-- ============================================================

-- Exercise 6.1: An anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

-- 6.1 question: wrong label after END
SELECT * FROM show_error($q$
DO $b$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END wrong_label $b$
$q$);


-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total     NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;

    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE '1) Outer fee_total before the subblock: %', fee_total;

    <<recent>>
    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT SUM(fee) INTO fee_total
          FROM rentals
         WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2) Subblock fee_total (from 2025-01-01): %', fee_total;
        RAISE NOTICE '3) Outer fee_total via label from inside: %', rental_report.fee_total;
    END recent;

    RAISE NOTICE '4) Outer fee_total after the subblock: %', fee_total;
END rental_report $$;


-- Exercise 6.3: Declarations are local
-- second subblock tries to read a variable from the first one -> error
SELECT * FROM show_error($q$
DO $b$
<<outer_block>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT SUM(fee) INTO fee_total FROM rentals;

    <<first_sub>>
    DECLARE
        recent_cnt INTEGER;
    BEGIN
        SELECT COUNT(*) INTO recent_cnt
          FROM rentals
         WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE 'first_sub: recent_cnt = %', recent_cnt;
    END first_sub;

    <<second_sub>>
    BEGIN
        RAISE NOTICE 'second_sub: recent_cnt = %', recent_cnt;
    END second_sub;
END outer_block $b$
$q$);

-- fix: declare recent_cnt in the outer block, now both subblocks see it
DO $$
<<outer_block>>
DECLARE
    fee_total  NUMERIC;
    recent_cnt INTEGER;
BEGIN
    SELECT SUM(fee) INTO fee_total FROM rentals;

    <<first_sub>>
    BEGIN
        SELECT COUNT(*) INTO recent_cnt
          FROM rentals
         WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE 'first_sub: recent_cnt = %', recent_cnt;
    END first_sub;

    <<second_sub>>
    BEGIN
        RAISE NOTICE 'second_sub: recent_cnt = %', recent_cnt;
    END second_sub;
END outer_block $$;


-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(p_from_date DATE,
                                     OUT before_total NUMERIC,
                                     OUT after_total  NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO before_total
      FROM rentals
     WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0) INTO after_total
      FROM rentals
     WHERE start_date >= p_from_date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

-- check: before + after should equal the total
SELECT f.before_total,
       f.after_total,
       f.before_total + f.after_total   AS split_sum,
       (SELECT SUM(fee) FROM rentals)   AS table_total
  FROM fee_split(DATE '2025-01-01') f;


-- ============================================================
-- Part 7: Practical Scenarios
-- ============================================================

-- Exercise 7.1: Station occupancy
-- if capacity is 0 I return NULL for the percent
-- you can't take a percent of 0 docks, and 0 or 100 would be wrong
CREATE OR REPLACE FUNCTION station_load(p_station_id INT,
                                        OUT bikes_parked INT,
                                        OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT capacity INTO v_capacity
      FROM stations
     WHERE station_id = p_station_id;

    SELECT COUNT(*) INTO bikes_parked
      FROM bikes
     WHERE station_id = p_station_id;

    capacity_pct := ROUND(bikes_parked * 100.0 / NULLIF(v_capacity, 0), 1);
END; $$
LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
  FROM stations s, LATERAL station_load(s.station_id) l;


-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (t_name    VARCHAR,
               t_rentals INT,
               t_spent   NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT m.full_name,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r ON r.member_id = m.member_id
         GROUP BY m.member_id, m.full_name
         ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.full_name
         LIMIT p_limit;
END; $$
LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);


-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (i_member VARCHAR,
               i_model  VARCHAR,
               i_days   INT,
               i_amount NUMERIC,
               i_status VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT m.full_name,
               b.model,
               COALESCE(r.end_date, CURRENT_DATE) - r.start_date,
               ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
               (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
          FROM rentals r
          JOIN members m ON m.member_id = r.member_id
          JOIN bikes   b ON b.bike_id   = r.bike_id
         WHERE r.rental_id = p_rental_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);   -- 8 days, 74.00, CLOSED, same as the fee in the table
SELECT * FROM rental_invoice(19);   -- OPEN, changes every day because of CURRENT_DATE

-- check rental 11: my amount vs fee in the table
SELECT i.i_amount, r.fee AS stored_fee, i.i_amount = r.fee AS equal
  FROM rental_invoice(11) i, rentals r
 WHERE r.rental_id = 11;


-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT COUNT(DISTINCT m.member_id)::INT,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r ON r.member_id = m.member_id
         WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

-- second version, only rentals from p_from_date
-- date goes in ON, otherwise members without rentals disappear
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT COUNT(DISTINCT m.member_id)::INT,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r
                 ON r.member_id = m.member_id
                AND r.start_date >= p_from_date
         WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
SELECT * FROM city_report('Astana');
SELECT * FROM city_report('Astana', DATE '2025-01-01');

-- 7.4 question: date in ON vs in WHERE, Almaty from 2025-01-01
SELECT 'date in ON'                  AS variant,
       COUNT(DISTINCT m.member_id)   AS members,
       COUNT(r.rental_id)            AS rentals,
       COALESCE(SUM(r.fee), 0)       AS revenue
  FROM members m
  LEFT JOIN rentals r
         ON r.member_id = m.member_id
        AND r.start_date >= DATE '2025-01-01'
 WHERE m.city = 'Almaty'
UNION ALL
SELECT 'date in WHERE',
       COUNT(DISTINCT m.member_id),
       COUNT(r.rental_id),
       COALESCE(SUM(r.fee), 0)
  FROM members m
  LEFT JOIN rentals r ON r.member_id = m.member_id
 WHERE m.city = 'Almaty'
   AND r.start_date >= DATE '2025-01-01';

-- ============================================================
-- end
-- ==========================================================================================================