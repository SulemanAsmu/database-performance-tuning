-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Oracle Query Hints
--              Used to guide the optimizer
--              when it makes wrong decisions
-- =============================================

-- -----------------------------------------------
-- 1. INDEX Hint - Force use of specific index
--    Use when optimizer ignores a useful index
-- -----------------------------------------------
SELECT /*+ INDEX(e idx_emp_dept_status) */
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName  AS FullName,
    e.JobTitle,
    e.Salary
FROM Employees e
WHERE e.DepartmentID = 1
  AND e.Status = 'Active';

-- -----------------------------------------------
-- 2. FULL Hint - Force Full Table Scan
--    Use when index scan is slower
--    (fetching > 20-30% of rows)
-- -----------------------------------------------
SELECT /*+ FULL(e) */
    EmployeeID,
    FirstName,
    LastName,
    Salary
FROM Employees e
WHERE Salary > 50000;

-- -----------------------------------------------
-- 3. PARALLEL Hint - Use parallel execution
--    Use for large table operations in batch jobs
-- -----------------------------------------------
SELECT /*+ PARALLEL(o, 4) */
    EXTRACT(YEAR FROM OrderDate)    AS OrderYear,
    EXTRACT(MONTH FROM OrderDate)   AS OrderMonth,
    COUNT(*)                        AS TotalOrders,
    SUM(TotalAmount)                AS TotalRevenue
FROM Orders o
GROUP BY
    EXTRACT(YEAR FROM OrderDate),
    EXTRACT(MONTH FROM OrderDate)
ORDER BY OrderYear, OrderMonth;

-- -----------------------------------------------
-- 4. USE_NL Hint - Force Nested Loop Join
--    Best for small result sets
-- -----------------------------------------------
SELECT /*+ USE_NL(e d) */
    e.FirstName || ' ' || e.LastName  AS EmployeeName,
    d.DepartmentName
FROM Employees e, Departments d
WHERE e.DepartmentID = d.DepartmentID
  AND e.EmployeeID = 1;

-- -----------------------------------------------
-- 5. USE_HASH Hint - Force Hash Join
--    Best for large table joins
-- -----------------------------------------------
SELECT /*+ USE_HASH(o c) */
    c.FirstName || ' ' || c.LastName  AS CustomerName,
    COUNT(o.OrderID)                  AS TotalOrders,
    SUM(o.TotalAmount)                AS TotalSpent
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;

-- -----------------------------------------------
-- 6. RESULT_CACHE Hint
--    Cache query result in memory
--    Use for frequently-run, rarely-changing queries
-- -----------------------------------------------
SELECT /*+ RESULT_CACHE */
    DepartmentID,
    DepartmentName,
    Location,
    Budget
FROM Departments
ORDER BY DepartmentName;
