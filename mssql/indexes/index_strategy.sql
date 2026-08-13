-- =============================================
-- Database:    SQL Server 2019
-- Author:      Suleman
-- Description: SQL Server Index Strategy
-- =============================================

USE CompanyDB;
GO

-- -----------------------------------------------
-- 1. Check Existing Indexes
-- -----------------------------------------------
SELECT
    t.name                      AS TableName,
    i.name                      AS IndexName,
    i.type_desc                 AS IndexType,
    i.is_unique,
    i.is_primary_key,
    ic.key_ordinal,
    c.name                      AS ColumnName,
    ic.is_included_column
FROM sys.tables t
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
INNER JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
INNER JOIN sys.columns c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE t.name IN ('Employees','Orders','OrderDetails')
ORDER BY TableName, IndexName, ic.key_ordinal;

-- -----------------------------------------------
-- 2. Create Indexes
-- -----------------------------------------------
CREATE INDEX idx_emp_email
ON Employees(Email);

CREATE INDEX idx_emp_dept_status
ON Employees(DepartmentID, Status)
INCLUDE (FirstName, LastName, Salary);

CREATE INDEX idx_ord_date_status
ON Orders(OrderDate DESC, Status)
INCLUDE (CustomerID, TotalAmount);

-- -----------------------------------------------
-- 3. Find Missing Indexes (DMV)
-- -----------------------------------------------
SELECT TOP 20
    ROUND(migs.avg_total_user_cost *
          migs.avg_user_impact *
         (migs.user_seeks + migs.user_scans), 0)    AS improvement_measure,
    migs.user_seeks,
    migs.user_scans,
    migs.avg_user_impact,
    mid.statement                                    AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    'CREATE INDEX [IX_'
        + OBJECT_NAME(mid.OBJECT_ID)
        + '_missing_' + CAST(mid.index_handle AS VARCHAR)
        + '] ON ' + mid.statement
        + ' (' + ISNULL(mid.equality_columns,'')
        + CASE WHEN mid.inequality_columns IS NOT NULL
               THEN (CASE WHEN mid.equality_columns IS NOT NULL
                          THEN ',' ELSE '' END)
                    + mid.inequality_columns
               ELSE '' END + ')'
        + ISNULL(' INCLUDE (' + mid.included_columns + ')','')
        AS create_index_statement
FROM sys.dm_db_missing_index_groups AS mig
INNER JOIN sys.dm_db_missing_index_group_stats AS migs
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON mig.index_handle = mid.index_handle
ORDER BY improvement_measure DESC;

-- -----------------------------------------------
-- 4. Find Unused Indexes
-- -----------------------------------------------
SELECT
    OBJECT_NAME(i.object_id)    AS TableName,
    i.name                      AS IndexName,
    i.type_desc,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id  = ius.object_id
    AND i.index_id  = ius.index_id
    AND ius.database_id = DB_ID()
WHERE OBJECT_NAME(i.object_id) IN
      ('Employees','Orders','OrderDetails')
  AND i.type_desc  <> 'HEAP'
  AND ISNULL(ius.user_seeks,0)   = 0
  AND ISNULL(ius.user_scans,0)   = 0
  AND ISNULL(ius.user_lookups,0) = 0
ORDER BY ISNULL(ius.user_updates,0) DESC;

-- -----------------------------------------------
-- 5. Index Rebuild and Reorganize
-- -----------------------------------------------
-- Check fragmentation
SELECT
    OBJECT_NAME(ips.object_id)         AS TableName,
    i.name                             AS IndexName,
    ips.index_type_desc,
    ROUND(ips.avg_fragmentation_in_percent, 2) AS fragmentation_pct,
    ips.page_count
FROM sys.dm_db_index_physical_stats(
    DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
INNER JOIN sys.indexes i
    ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
WHERE ips.page_count > 100
ORDER BY fragmentation_pct DESC;

-- Reorganize if 5-30% fragmented (online, no lock)
ALTER INDEX idx_emp_dept_status ON Employees REORGANIZE;

-- Rebuild if >30% fragmented
ALTER INDEX idx_emp_dept_status ON Employees
REBUILD WITH (ONLINE = ON);

-- Rebuild ALL indexes on a table
ALTER INDEX ALL ON Employees
REBUILD WITH (ONLINE = ON, FILLFACTOR = 80);
