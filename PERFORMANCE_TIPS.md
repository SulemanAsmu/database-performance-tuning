# 📚 Database Performance Tuning - Best Practices

## 🔑 Golden Rules of Performance Tuning

### Rule 1: Always Measure Before and After
- Capture execution time before making changes
- Document the improvement percentage
- Keep both versions of the query

### Rule 2: Index Strategy
- Index columns used in WHERE, JOIN, ORDER BY
- Avoid over-indexing (slows down INSERT/UPDATE)
- Use composite indexes wisely (column order matters)
- Monitor unused indexes and drop them

### Rule 3: Query Writing Best Practices
| ❌ Avoid                          | ✅ Use Instead                     |
|----------------------------------|-----------------------------------|
| SELECT *                         | SELECT only needed columns         |
| Functions on indexed columns     | Avoid functions in WHERE clause    |
| Implicit data type conversion    | Explicit CAST/CONVERT              |
| OR conditions on indexed columns | UNION instead of OR                |
| NOT IN with NULL values          | NOT EXISTS                         |
| Correlated subqueries            | JOINs or CTEs                      |
| HAVING instead of WHERE          | Filter with WHERE first            |

### Rule 4: Statistics
- Keep statistics up to date
- Outdated statistics = bad execution plans
- Schedule regular statistics updates

### Rule 5: Monitor Regularly
- Check wait statistics weekly
- Review slow query logs daily
- Monitor index usage monthly
- Check disk space and fragmentation
