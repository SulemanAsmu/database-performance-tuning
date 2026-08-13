-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Index Creation and Strategy
-- =============================================

-- -----------------------------------------------
-- 1. Check existing indexes on a table
-- -----------------------------------------------
SELECT
    i.INDEX_NAME,
    i.INDEX_TYPE,
    i.UNIQUENESS,
    i.STATUS,
    ic.COLUMN_NAME,
    ic.COLUMN_POSITION,
    ic.DESCEND
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic
    ON i.INDEX_NAME = ic.INDEX_NAME
WHERE i.TABLE_NAME = 'EMPLOYEES'
ORDER BY i.INDEX_NAME, ic.COLUMN_POSITION;

-- -----------------------------------------------
-- 2. Create B-Tree Index (Most Common)
--    Use for: High cardinality columns
--    Example: Email, EmployeeID lookups
-- -----------------------------------------------
CREATE INDEX idx_emp_email
ON Employees(Email);

CREATE INDEX idx_emp_dept
ON Employees(DepartmentID);

CREATE INDEX idx_emp_status
ON Employees(Status);

-- -----------------------------------------------
-- 3. Composite Index
--    Column ORDER matters!
--    Most selective column FIRST
--    Use for: Queries filtering multiple columns
-- -----------------------------------------------
-- For queries like:
-- WHERE DepartmentID = ? AND Status = 'Active'
CREATE INDEX idx_emp_dept_status
ON Employees(DepartmentID, Status);

-- For Orders search by date and status
-- WHERE OrderDate BETWEEN ? AND ? AND Status = ?
CREATE INDEX idx_ord_date_status
ON Orders(OrderDate, Status);

-- -----------------------------------------------
-- 4. Function-Based Index
--    Use when you query with UPPER/LOWER/functions
-- -----------------------------------------------
-- For queries like:
-- WHERE UPPER(Email) = UPPER('input')
CREATE INDEX idx_emp_email_upper
ON Employees(UPPER(Email));

-- -----------------------------------------------
-- 5. Bitmap Index
--    Use ONLY for LOW cardinality columns
--    (few distinct values like Status, Gender)
--    ⚠️ WARNING: NOT for OLTP - use in Data Warehouse
-- -----------------------------------------------
CREATE BITMAP INDEX idx_emp_status_bmp
ON Employees(Status);

-- -----------------------------------------------
-- 6. Find MISSING Indexes
--    Columns frequently in WHERE but not indexed
-- -----------------------------------------------
SELECT
    s.SQL_TEXT,
    s.EXECUTIONS,
    s.DISK_READS,
    s.BUFFER_GETS,
    ROUND(s.DISK_READS / DECODE(s.EXECUTIONS,0,1,s.EXECUTIONS),2)
        AS DISK_READS_PER_EXEC,
    ROUND(s.BUFFER_GETS / DECODE(s.EXECUTIONS,0,1,s.EXECUTIONS),2)
        AS BUFGETS_PER_EXEC
FROM V$SQLAREA s
WHERE s.DISK_READS > 1000
  AND s.EXECUTIONS > 10
ORDER BY DISK_READS_PER_EXEC DESC
FETCH FIRST 20 ROWS ONLY;

-- -----------------------------------------------
-- 7. Find UNUSED Indexes
--    Indexes that have never been used
-- -----------------------------------------------
-- First enable monitoring
ALTER INDEX idx_emp_email MONITORING USAGE;

-- After some time, check usage
SELECT
    INDEX_NAME,
    TABLE_NAME,
    MONITORING,
    USED,
    START_MONITORING,
    END_MONITORING
FROM V$OBJECT_USAGE
ORDER BY USED, INDEX_NAME;

-- Drop unused indexes (saves space and speeds up DML)
-- ALTER INDEX idx_unused_index NOMONITORING USAGE;
-- DROP INDEX idx_unused_index;

-- -----------------------------------------------
-- 8. Check Index Fragmentation
-- -----------------------------------------------
ANALYZE INDEX idx_emp_email VALIDATE STRUCTURE;

SELECT
    NAME,
    HEIGHT,
    BLOCKS,
    LF_ROWS,
    LF_BLKS,
    DEL_LF_ROWS,
    ROUND(DEL_LF_ROWS / DECODE(LF_ROWS,0,1,LF_ROWS) * 100, 2)
        AS PCT_DELETED
FROM INDEX_STATS
WHERE NAME = 'IDX_EMP_EMAIL';

-- Rebuild fragmented index
ALTER INDEX idx_emp_email REBUILD;

-- Rebuild with parallel (faster for large indexes)
ALTER INDEX idx_emp_email REBUILD PARALLEL 4;
ALTER INDEX idx_emp_email NOPARALLEL;
