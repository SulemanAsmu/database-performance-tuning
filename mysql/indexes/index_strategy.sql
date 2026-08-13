-- =============================================
-- Database:    MySQL 8.0
-- Author:      Suleman
-- Description: MySQL Index Strategy
-- =============================================

USE CompanyDB;

-- -----------------------------------------------
-- 1. Show existing indexes on a table
-- -----------------------------------------------
SHOW INDEX FROM Employees;
SHOW INDEX FROM Orders;

-- -----------------------------------------------
-- 2. Create Indexes
-- -----------------------------------------------
-- Single column index
CREATE INDEX idx_emp_email      ON Employees(Email);
CREATE INDEX idx_emp_dept       ON Employees(DepartmentID);
CREATE INDEX idx_emp_status     ON Employees(Status);

-- Composite index
CREATE INDEX idx_emp_dept_status ON Employees(DepartmentID, Status);
CREATE INDEX idx_ord_date_status ON Orders(OrderDate, Status);

-- Covering index (includes all columns needed by query)
CREATE INDEX idx_ord_covering
ON Orders(CustomerID, OrderDate, Status)
INCLUDE (TotalAmount);       -- MySQL 8.0+

-- -----------------------------------------------
-- 3. Find Missing Indexes Using EXPLAIN
-- -----------------------------------------------
-- Look for type = 'ALL' which means full table scan
EXPLAIN
SELECT * FROM Employees
WHERE DepartmentID = 1 AND Status = 'Active';

-- EXPLAIN FORMAT=JSON for detailed output
EXPLAIN FORMAT=JSON
SELECT e.FirstName, e.LastName, d.DepartmentName
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.Status = 'Active';

-- -----------------------------------------------
-- 4. Find Unused Indexes
-- -----------------------------------------------
SELECT
    OBJECT_SCHEMA                AS db_name,
    OBJECT_NAME                  AS table_name,
    INDEX_NAME,
    COUNT_STAR                   AS total_accesses,
    COUNT_READ,
    COUNT_WRITE
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE INDEX_NAME IS NOT NULL
  AND COUNT_STAR = 0
  AND OBJECT_SCHEMA = 'companydb'
ORDER BY OBJECT_NAME, INDEX_NAME;

-- -----------------------------------------------
-- 5. Table and Index Sizes
-- -----------------------------------------------
SELECT
    TABLE_NAME,
    ROUND(DATA_LENGTH/1024/1024, 2)     AS data_mb,
    ROUND(INDEX_LENGTH/1024/1024, 2)    AS index_mb,
    ROUND((DATA_LENGTH+INDEX_LENGTH)
          /1024/1024, 2)                AS total_mb,
    TABLE_ROWS                          AS est_rows
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'companydb'
ORDER BY total_mb DESC;
