-- =============================================
-- Database:    MySQL 8.0
-- Author:      Suleman
-- Description: Query Optimization Examples
-- =============================================

USE CompanyDB;

-- ===============================================
-- EXAMPLE 1: Use EXPLAIN to Check Query Plan
-- ===============================================
-- Always run EXPLAIN before and after optimization
EXPLAIN SELECT * FROM Employees WHERE DepartmentID = 1;

-- ===============================================
-- EXAMPLE 2: Avoid Functions on Indexed Columns
-- ===============================================

-- ❌ BEFORE - Causes full table scan
SELECT EmployeeID, Email
FROM Employees
WHERE YEAR(HireDate) = 2020;

-- ✅ AFTER - Uses index on HireDate
SELECT EmployeeID, Email, HireDate
FROM Employees
WHERE HireDate BETWEEN '2020-01-01' AND '2020-12-31';

-- ===============================================
-- EXAMPLE 3: Replace OR with UNION
-- ===============================================

-- ❌ BEFORE - OR can prevent index usage
SELECT EmployeeID, FirstName, LastName, Status
FROM Employees
WHERE Status = 'Active' OR DepartmentID = 1;

-- ✅ AFTER - UNION allows index on each branch
SELECT EmployeeID, FirstName, LastName, Status
FROM Employees WHERE Status = 'Active'
UNION
SELECT EmployeeID, FirstName, LastName, Status
FROM Employees WHERE DepartmentID = 1;

-- ===============================================
-- EXAMPLE 4: Use EXISTS instead of COUNT
-- ===============================================

-- ❌ BEFORE - Counts ALL rows then checks
SELECT CustomerID, FirstName
FROM Customers
WHERE (
    SELECT COUNT(*) FROM Orders
    WHERE Orders.CustomerID = Customers.CustomerID
) > 0;

-- ✅ AFTER - Stops at first match found
SELECT CustomerID, FirstName, LastName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);

-- ===============================================
-- EXAMPLE 5: Slow Query Log Analysis
-- ===============================================

-- Enable slow query log
SET GLOBAL slow_query_log      = 'ON';
SET GLOBAL long_query_time     = 1;     -- Log queries > 1 second
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- Check slow query log location
SHOW VARIABLES LIKE 'slow_query_log_file';

-- View slow queries in performance schema
SELECT
    DIGEST_TEXT                         AS query_pattern,
    COUNT_STAR                          AS executions,
    ROUND(AVG_TIMER_WAIT/1000000000,3)  AS avg_sec,
    ROUND(MAX_TIMER_WAIT/1000000000,3)  AS max_sec,
    SUM_ROWS_EXAMINED                   AS rows_examined,
    SUM_ROWS_SENT                       AS rows_returned
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'companydb'
ORDER BY avg_sec DESC
LIMIT 10;
