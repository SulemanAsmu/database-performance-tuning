-- =============================================
-- Database:    PostgreSQL 15
-- Author:      Suleman
-- Description: PostgreSQL Index Strategy
-- =============================================

\c companydb;

-- -----------------------------------------------
-- 1. Check Existing Indexes
-- -----------------------------------------------
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- -----------------------------------------------
-- 2. Create Indexes
-- -----------------------------------------------
-- Regular B-Tree indexes
CREATE INDEX idx_emp_email
    ON Employees(Email);

CREATE INDEX idx_emp_dept
    ON Employees(DepartmentID);

-- Composite Index
CREATE INDEX idx_emp_dept_status
    ON Employees(DepartmentID, Status);

-- Partial Index (only index active employees)
-- Great for tables with many inactive records
CREATE INDEX idx_emp_active
    ON Employees(DepartmentID, Salary)
    WHERE Status = 'Active';

-- Index for text search
CREATE INDEX idx_emp_lastname
    ON Employees USING btree (LastName varchar_pattern_ops);

-- -----------------------------------------------
-- 3. EXPLAIN ANALYZE - Show actual plan
-- -----------------------------------------------
EXPLAIN ANALYZE
SELECT
    e.FirstName || ' ' || e.LastName  AS FullName,
    d.DepartmentName,
    e.Salary
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.Status = 'Active'
ORDER BY e.Salary DESC;

-- -----------------------------------------------
-- 4. Find Missing Indexes
--    Tables with high sequential scans
-- -----------------------------------------------
SELECT
    schemaname,
    relname                         AS table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    seq_tup_read / seq_scan         AS avg_seq_read,
    pg_size_pretty(
        pg_relation_size(relid))    AS table_size
FROM pg_stat_user_tables
WHERE seq_scan > 50
  AND schemaname = 'public'
ORDER BY seq_tup_read DESC;

-- -----------------------------------------------
-- 5. Find Unused Indexes
-- -----------------------------------------------
SELECT
    schemaname,
    relname                         AS table_name,
    indexrelname                    AS index_name,
    idx_scan                        AS times_used,
    pg_size_pretty(
        pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- -----------------------------------------------
-- 6. VACUUM and ANALYZE Maintenance
-- -----------------------------------------------
-- Update statistics for query planner
ANALYZE Employees;
ANALYZE Orders;

-- Clean dead tuples and update statistics
VACUUM ANALYZE Employees;
VACUUM ANALYZE Orders;

-- Full vacuum (rewrites table - use during maintenance)
VACUUM FULL Employees;
