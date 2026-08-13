-- =============================================
-- Database:    Oracle 19c/21c
-- Author:      Suleman
-- Description: Wait Statistics Analysis
--              Identify what Oracle is waiting for
-- =============================================

-- -----------------------------------------------
-- 1. Current Top Wait Events (Right Now)
-- -----------------------------------------------
SELECT
    EVENT,
    TOTAL_WAITS,
    TOTAL_TIMEOUTS,
    TIME_WAITED,
    AVERAGE_WAIT,
    WAIT_CLASS
FROM V$SYSTEM_EVENT
WHERE WAIT_CLASS != 'Idle'
ORDER BY TIME_WAITED DESC
FETCH FIRST 15 ROWS ONLY;

-- -----------------------------------------------
-- 2. Active Sessions and What They Are Waiting For
-- -----------------------------------------------
SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.PROGRAM,
    s.MODULE,
    s.EVENT,
    s.WAIT_CLASS,
    s.SECONDS_IN_WAIT,
    s.SQL_ID
FROM V$SESSION s
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
  AND s.WAIT_CLASS != 'Idle'
ORDER BY s.SECONDS_IN_WAIT DESC;

-- -----------------------------------------------
-- 3. Find Blocking Sessions
--    Who is blocking whom?
-- -----------------------------------------------
SELECT
    b.SID                               AS BLOCKING_SID,
    b.USERNAME                          AS BLOCKING_USER,
    b.STATUS                            AS BLOCKING_STATUS,
    w.SID                               AS WAITING_SID,
    w.USERNAME                          AS WAITING_USER,
    w.EVENT                             AS WAIT_EVENT,
    w.SECONDS_IN_WAIT                   AS WAIT_SECONDS,
    sq.SQL_TEXT                         AS BLOCKING_SQL
FROM V$SESSION w
JOIN V$SESSION b
    ON w.BLOCKING_SESSION = b.SID
LEFT JOIN V$SQL sq
    ON b.SQL_ID = sq.SQL_ID
ORDER BY w.SECONDS_IN_WAIT DESC;

-- -----------------------------------------------
-- 4. Kill Blocking Session (Use Carefully!)
-- -----------------------------------------------
-- ALTER SYSTEM KILL SESSION 'SID,SERIAL#' IMMEDIATE;
-- Example:
-- ALTER SYSTEM KILL SESSION '125,1234' IMMEDIATE;

-- -----------------------------------------------
-- 5. Top Wait Events from AWR
--    (Requires Diagnostics Pack license)
-- -----------------------------------------------
SELECT
    EVENT_NAME,
    WAIT_CLASS,
    TOTAL_WAITS,
    ROUND(TIME_WAITED_MICRO/1000000, 2)  AS TIME_WAITED_SECS,
    ROUND(TIME_WAITED_MICRO/1000000
        / DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS),4)
                                          AS AVG_WAIT_SECS
FROM DBA_HIST_SYSTEM_EVENT
WHERE SNAP_ID = (SELECT MAX(SNAP_ID) FROM DBA_HIST_SNAPSHOT)
  AND WAIT_CLASS != 'Idle'
ORDER BY TIME_WAITED_SECS DESC
FETCH FIRST 10 ROWS ONLY;

-- -----------------------------------------------
-- 6. I/O Performance Check
-- -----------------------------------------------
SELECT
    FILE#,
    NAME,
    PHYRDS,
    PHYWRTS,
    READTIM,
    WRITETIM,
    ROUND(READTIM  / DECODE(PHYRDS, 0,1,PHYRDS),   2) AS AVG_READ_MS,
    ROUND(WRITETIM / DECODE(PHYWRTS,0,1,PHYWRTS),  2) AS AVG_WRITE_MS
FROM V$FILESTAT fs
JOIN V$DATAFILE df ON fs.FILE# = df.FILE#
ORDER BY READTIM DESC;
