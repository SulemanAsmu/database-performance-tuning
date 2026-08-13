-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Statistics and Maintenance Scripts
-- =============================================

-- -----------------------------------------------
-- 1. Check When Statistics Were Last Updated
-- -----------------------------------------------
SELECT
    TABLE_NAME,
    NUM_ROWS,
    BLOCKS,
    LAST_ANALYZED,
    ROUND((SYSDATE - LAST_ANALYZED),0)  AS DAYS_SINCE_ANALYZED,
    STALE_STATS
FROM USER_TAB_STATISTICS
ORDER BY DAYS_SINCE_ANALYZED DESC NULLS FIRST;

-- -----------------------------------------------
-- 2. Gather Statistics for One Table
-- -----------------------------------------------
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname     => USER,
        tabname     => 'EMPLOYEES',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt   => 'FOR ALL COLUMNS SIZE AUTO',
        cascade      => TRUE,    -- Include indexes
        degree       => 4        -- Parallel degree
    );
END;
/

-- -----------------------------------------------
-- 3. Gather Statistics for ALL Tables (Schema)
-- -----------------------------------------------
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(
        ownname          => USER,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
        cascade          => TRUE,
        degree           => 4,
        options          => 'GATHER STALE'  -- Only stale stats
    );
END;
/

-- -----------------------------------------------
-- 4. Rebuild All Fragmented Indexes
-- -----------------------------------------------
BEGIN
    FOR idx IN (
        SELECT
            INDEX_NAME,
            TABLE_NAME
        FROM USER_INDEXES
        WHERE STATUS = 'VALID'
          AND TEMPORARY = 'N'
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'ALTER INDEX ' || idx.INDEX_NAME || ' REBUILD ONLINE';
            DBMS_OUTPUT.PUT_LINE(
                '✅ Rebuilt: ' || idx.INDEX_NAME);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(
                    '❌ Failed: ' || idx.INDEX_NAME ||
                    ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- -----------------------------------------------
-- 5. Check Tablespace Usage
-- -----------------------------------------------
SELECT
    df.TABLESPACE_NAME,
    ROUND(df.TOTAL_MB, 2)                   AS TOTAL_MB,
    ROUND(df.TOTAL_MB - fs.FREE_MB, 2)      AS USED_MB,
    ROUND(fs.FREE_MB, 2)                    AS FREE_MB,
    ROUND((df.TOTAL_MB - fs.FREE_MB)
        / df.TOTAL_MB * 100, 2)             AS PCT_USED
FROM (
    SELECT TABLESPACE_NAME,
           SUM(BYTES)/1024/1024 AS TOTAL_MB
    FROM DBA_DATA_FILES
    GROUP BY TABLESPACE_NAME
) df
JOIN (
    SELECT TABLESPACE_NAME,
           SUM(BYTES)/1024/1024 AS FREE_MB
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
) fs ON df.TABLESPACE_NAME = fs.TABLESPACE_NAME
ORDER BY PCT_USED DESC;
