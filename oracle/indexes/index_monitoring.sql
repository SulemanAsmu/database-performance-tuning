-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Index Monitoring and Reporting
-- =============================================

-- -----------------------------------------------
-- 1. All Indexes with Size Information
-- -----------------------------------------------
SELECT
    i.TABLE_NAME,
    i.INDEX_NAME,
    i.INDEX_TYPE,
    i.UNIQUENESS,
    i.STATUS,
    s.BYTES / 1024 / 1024          AS SIZE_MB,
    i.NUM_ROWS,
    i.DISTINCT_KEYS,
    i.CLUSTERING_FACTOR,
    i.LAST_ANALYZED
FROM USER_INDEXES i
JOIN USER_SEGMENTS s
    ON i.INDEX_NAME = s.SEGMENT_NAME
ORDER BY SIZE_MB DESC;

-- -----------------------------------------------
-- 2. Index to Table Size Ratio
--    High ratio means too many indexes
-- -----------------------------------------------
SELECT
    t.TABLE_NAME,
    ROUND(ts.BYTES/1024/1024, 2)   AS TABLE_SIZE_MB,
    COUNT(i.INDEX_NAME)            AS NUM_INDEXES,
    ROUND(SUM(is2.BYTES)/1024/1024,2) AS TOTAL_INDEX_SIZE_MB,
    ROUND(SUM(is2.BYTES) / DECODE(ts.BYTES,0,1,ts.BYTES) * 100, 2)
                                   AS INDEX_TO_TABLE_PCT
FROM USER_TABLES t
JOIN USER_SEGMENTS ts
    ON t.TABLE_NAME = ts.SEGMENT_NAME
LEFT JOIN USER_INDEXES i
    ON t.TABLE_NAME = i.TABLE_NAME
LEFT JOIN USER_SEGMENTS is2
    ON i.INDEX_NAME = is2.SEGMENT_NAME
GROUP BY t.TABLE_NAME, ts.BYTES
ORDER BY TOTAL_INDEX_SIZE_MB DESC;

-- -----------------------------------------------
-- 3. Indexes That Need Rebuilding
--    When PCT_DELETED > 20% rebuild is recommended
-- -----------------------------------------------
BEGIN
    FOR idx IN (
        SELECT INDEX_NAME
        FROM USER_INDEXES
        WHERE STATUS = 'VALID'
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'ANALYZE INDEX ' || idx.INDEX_NAME || ' VALIDATE STRUCTURE';

            INSERT INTO TEMP_INDEX_STATS
            SELECT idx.INDEX_NAME,
                   HEIGHT, BLOCKS, LF_ROWS,
                   DEL_LF_ROWS,
                   ROUND(DEL_LF_ROWS/DECODE(LF_ROWS,0,1,LF_ROWS)*100,2)
            FROM INDEX_STATS;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/
