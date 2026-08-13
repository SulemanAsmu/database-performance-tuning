-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Query Optimization - Before & After
--              Real examples of slow queries
--              and their optimized versions
-- =============================================

-- ===============================================
-- EXAMPLE 1: Avoid SELECT *
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: Fetches ALL columns, uses more memory
--          and I/O, prevents index-only scans
SELECT *
FROM Employees
WHERE DepartmentID = 1;

-- ✅ AFTER - Optimized
-- Solution: Select only needed columns
--           Can use index-only scan
SELECT
    EmployeeID,
    FirstName || ' ' || LastName  AS FullName,
    JobTitle,
    Salary
FROM Employees
WHERE DepartmentID = 1
ORDER BY LastName;

-- ===============================================
-- EXAMPLE 2: Avoid Functions on Indexed Columns
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: UPPER() on Email prevents index usage
--          Causes FULL TABLE SCAN every time
SELECT EmployeeID, FirstName, LastName, Email
FROM Employees
WHERE UPPER(Email) = UPPER('sarah.johnson@company.com');

-- ✅ AFTER - Option 1: Store data consistently
-- Solution: Always store emails in lowercase
--           and query in lowercase
SELECT EmployeeID, FirstName, LastName, Email
FROM Employees
WHERE Email = LOWER('sarah.johnson@company.com');

-- ✅ AFTER - Option 2: Function-Based Index
-- Create the index first:
-- CREATE INDEX idx_emp_email_upper ON Employees(UPPER(Email));
-- Then query uses index automatically:
SELECT EmployeeID, FirstName, LastName, Email
FROM Employees
WHERE UPPER(Email) = 'SARAH.JOHNSON@COMPANY.COM';

-- ===============================================
-- EXAMPLE 3: Avoid Implicit Type Conversion
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: EmployeeID is NUMBER but we pass string
--          Oracle silently converts causing full scan
SELECT * FROM Employees WHERE EmployeeID = '5';

-- ✅ AFTER - Optimized
-- Solution: Use correct data type
SELECT
    EmployeeID, FirstName, LastName, JobTitle
FROM Employees
WHERE EmployeeID = 5;

-- ===============================================
-- EXAMPLE 4: Replace NOT IN with NOT EXISTS
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: NOT IN with subquery is slow
--          Especially if subquery returns NULL values
--          Forces full scan of outer table
SELECT CustomerID, FirstName, LastName
FROM Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Orders
    WHERE Status = 'Delivered'
);

-- ✅ AFTER - Optimized
-- Solution: NOT EXISTS is faster
--           Stops searching as soon as match found
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
      AND o.Status = 'Delivered'
);

-- ===============================================
-- EXAMPLE 5: Replace Correlated Subquery with JOIN
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: Correlated subquery runs ONCE PER ROW
--          For 1000 employees = 1000 subquery executions
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName  AS EmployeeName,
    e.Salary,
    (SELECT AVG(Salary) FROM Employees e2
     WHERE e2.DepartmentID = e.DepartmentID) AS DeptAvgSalary
FROM Employees e;

-- ✅ AFTER - Optimized
-- Solution: Use JOIN with aggregation
--           Runs aggregation ONCE not per row
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName  AS EmployeeName,
    e.Salary,
    da.AvgSalary                      AS DeptAvgSalary,
    ROUND(e.Salary - da.AvgSalary, 2) AS DiffFromAvg
FROM Employees e
JOIN (
    SELECT DepartmentID, AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY DepartmentID
) da ON e.DepartmentID = da.DepartmentID
ORDER BY e.DepartmentID, e.Salary DESC;

-- ===============================================
-- EXAMPLE 6: Use ROWNUM / FETCH FIRST properly
-- ===============================================

-- ❌ BEFORE - Bad Practice (Old Oracle way with subquery)
SELECT *
FROM (
    SELECT * FROM Employees ORDER BY Salary DESC
)
WHERE ROWNUM <= 5;

-- ✅ AFTER - Oracle 12c+ Modern Syntax
SELECT
    EmployeeID,
    FirstName || ' ' || LastName  AS FullName,
    JobTitle,
    Salary
FROM Employees
ORDER BY Salary DESC
FETCH FIRST 5 ROWS ONLY;

-- With offset (pagination)
SELECT
    EmployeeID,
    FirstName || ' ' || LastName  AS FullName,
    Salary
FROM Employees
ORDER BY Salary DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- ===============================================
-- EXAMPLE 7: Optimize GROUP BY with HAVING
-- ===============================================

-- ❌ BEFORE - Bad Practice
-- Problem: Aggregates ALL rows then filters
SELECT
    DepartmentID,
    COUNT(*) AS EmpCount,
    AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY DepartmentID
HAVING DepartmentID IN (1,2,3);

-- ✅ AFTER - Optimized
-- Solution: Filter with WHERE BEFORE aggregation
--           Reduces rows being aggregated
SELECT
    DepartmentID,
    COUNT(*)        AS EmpCount,
    AVG(Salary)     AS AvgSalary,
    MAX(Salary)     AS MaxSalary,
    MIN(Salary)     AS MinSalary
FROM Employees
WHERE DepartmentID IN (1,2,3)
  AND Status = 'Active'
GROUP BY DepartmentID
HAVING COUNT(*) > 1
ORDER BY AvgSalary DESC;
