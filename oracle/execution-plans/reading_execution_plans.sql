-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: How to Read and Analyze
--              Execution Plans in Oracle
-- =============================================

-- -----------------------------------------------
-- Method 1: EXPLAIN PLAN
-- -----------------------------------------------

-- Step 1: Generate the plan
EXPLAIN PLAN FOR
SELECT
    e.FirstName || ' ' || e.LastName  AS EmployeeName,
    d.DepartmentName,
    e.Salary
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.Status = 'Active'
ORDER BY e.Salary DESC;

-- Step 2: Read the plan
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(
    format => 'ALL'   -- Options: BASIC, TYPICAL, ALL
));

-- -----------------------------------------------
-- Method 2: AUTOTRACE (in SQL*Plus / SQL Developer)
-- -----------------------------------------------
SET AUTOTRACE ON;
SET AUTOTRACE TRACEONLY;        -- Show plan without results
SET AUTOTRACE TRACEONLY STAT;   -- Show only statistics

SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName  AS FullName,
    d.DepartmentName,
    e.Salary
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.DepartmentID = 1;

SET AUTOTRACE OFF;

-- -----------------------------------------------
-- Method 3: DBMS_XPLAN with actual runtime stats
-- -----------------------------------------------

-- Step 1: Enable statistics gathering
ALTER SESSION SET STATISTICS_LEVEL = ALL;

-- Step 2: Run the query with hint
SELECT /*+ GATHER_PLAN_STATISTICS */
    e.FirstName || ' ' || e.LastName  AS EmployeeName,
    d.DepartmentName,
    e.Salary
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.Status = 'Active';

-- Step 3: Get actual execution stats
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
    sql_id     => NULL,   -- NULL = last executed
    child_no   => 0,
    format     => 'ALLSTATS LAST'
));

-- -----------------------------------------------
-- What to look for in Execution Plans:
-- -----------------------------------------------
/*
    ⚠️  WARNING SIGNS:
    ┌─────────────────────────────────────────────┐
    │ TABLE ACCESS FULL  → Missing index          │
    │ High COST value    → Expensive operation    │
    │ Rows estimate ≠ actual → Stale statistics   │
    │ CARTESIAN JOIN     → Missing JOIN condition │
    │ SORT operations    → Missing index for ORDER│
    └─────────────────────────────────────────────┘

    ✅  GOOD SIGNS:
    ┌─────────────────────────────────────────────┐
    │ INDEX RANGE SCAN   → Using index correctly  │
    │ INDEX UNIQUE SCAN  → Best - single row      │
    │ HASH JOIN          → Good for large tables  │
    │ NESTED LOOPS       → Good for small sets    │
    └─────────────────────────────────────────────┘
*/

-- -----------------------------------------------
-- Find Top 10 Most Expensive SQL Queries
-- -----------------------------------------------
SELECT *
FROM (
    SELECT
        sql_id,
        ROUND(elapsed_time/1000000, 2)  AS elapsed_secs,
        executions,
        ROUND(elapsed_time/1000000
            / DECODE(executions,0,1,executions),2)
                                        AS avg_elapsed_secs,
        disk_reads,
        buffer_gets,
        ROUND(buffer_gets
            / DECODE(executions,0,1,executions),0)
                                        AS bufgets_per_exec,
        SUBSTR(sql_text,1,100)          AS sql_text
    FROM V$SQLAREA
    WHERE executions > 5
    ORDER BY avg_elapsed_secs DESC
)
WHERE ROWNUM <= 10;
