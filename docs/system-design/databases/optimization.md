---
title: Database Optimization
description: Indexing, query optimization, and performance tuning
sidebar_position: 33
---

# Database Optimization

> "Indexing frequently accessed database columns can significantly speed up retrieval."

Database optimization is crucial for maintaining high performance as data volume and query complexity grow.

## Indexing Strategies

### Index Types

#### B-Tree Index
**Characteristics**:
- **Balanced tree structure**: O(log n) search complexity
- **Range queries**: Efficient for range operations
- **Most common**: Default index type in most databases
- **Ordered storage**: Maintains key order

**Use Cases**:
- Equality queries (WHERE id = 123)
- Range queries (WHERE age BETWEEN 20 AND 30)
- Sorting operations (ORDER BY created_at)
- Prefix searches (WHERE name LIKE 'john%')

**Example**:
```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

#### Hash Index
**Characteristics**:
- **Hash table structure**: O(1) average lookup
- **Equality only**: No range queries
- **Memory intensive**: Requires more memory
- **Fast lookups**: Excellent for exact matches

**Use Cases**:
- Exact match queries (WHERE username = 'john')
- Key-value lookups
- In-memory databases
- Caching systems

#### Composite Index
**Characteristics**:
- **Multiple columns**: Single index on multiple fields
- **Column order matters**: Leftmost prefix rule
- **Reduced storage**: More efficient than multiple indexes
- **Query optimization**: Covers more query types

**Example**:
```sql
-- Index on (last_name, first_name)
CREATE INDEX idx_users_name ON users(last_name, first_name);

-- Supports these queries:
SELECT * FROM users WHERE last_name = 'Smith';
SELECT * FROM users WHERE last_name = 'Smith' AND first_name = 'John';
-- Does NOT support: WHERE first_name = 'John'
```

#### Partial Index
**Characteristics**:
- **Conditional indexing**: Index subset of rows
- **Smaller storage**: Reduced index size
- **Faster maintenance**: Less overhead
- **Targeted optimization**: Specific use cases

**Example**:
```sql
-- Index only active users
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active';

-- Index recent orders
CREATE INDEX idx_recent_orders ON orders(user_id) WHERE created_at > '2023-01-01';
```

### Index Design Principles

#### Selectivity
- **High selectivity**: Few rows per value (good for indexing)
- **Low selectivity**: Many rows per value (poor for indexing)
- **Cardinality**: Number of unique values
- **Rule of thumb**: Index columns with high selectivity

#### Leftmost Prefix Rule
- **Composite indexes**: Use leftmost columns first
- **Query optimization**: Match index column order
- **Index usage**: Must use prefix of index columns
- **Planning**: Consider common query patterns

#### Covering Indexes
- **All columns in index**: No table access needed
- **Improved performance**: Eliminates lookups
- **Storage trade-off**: Larger index size
- **Query optimization**: Ideal for specific queries

**Example**:
```sql
CREATE INDEX idx_order_summary ON orders(user_id, total, status);

-- This query uses only the index:
SELECT user_id, total, status FROM orders WHERE user_id = 123;
```

## Query Optimization

### Query Analysis

#### EXPLAIN Plan
**Purpose**: Understand query execution strategy
**Usage**: Analyze and optimize query performance
**Components**: Access methods, join strategies, cost estimates

**Example**:
```sql
EXPLAIN ANALYZE
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active'
  AND o.created_at > '2023-01-01';
```

#### Common Performance Issues
- **Full table scans**: No index usage
- **Nested loops**: Inefficient join strategies
- **Temporary tables**: Memory/disk overhead
- **Sorting operations**: Expensive ORDER BY clauses

### Optimization Techniques

#### Query Rewriting
- **Avoid SELECT ***: Specify needed columns
- **Use appropriate JOINs**: INNER vs OUTER joins
- **Optimize WHERE clauses**: SARGable predicates
- **Minimize subqueries**: Use JOINs instead

**Before**:
```sql
SELECT * FROM users WHERE id IN (
    SELECT user_id FROM orders WHERE total > 1000
);
```

**After**:
```sql
SELECT DISTINCT u.* FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.total > 1000;
```

#### Join Optimization
- **Join order**: Start with most selective table
- **Join types**: Choose appropriate join algorithm
- **Index usage**: Ensure join columns indexed
- **Join elimination**: Remove unnecessary joins

#### Subquery Optimization
- **Correlated subqueries**: Often slow
- **Derived tables**: Materialized subqueries
- **Common table expressions**: Query organization
- **Window functions**: Alternative to self-joins

## Database Configuration

### Memory Configuration

#### Buffer Pool
- **Purpose**: Cache frequently accessed data
- **Size**: 70-80% of available RAM
- **Impact**: Major performance factor
- **Monitoring**: Hit ratio tracking

**MySQL Example**:
```sql
-- Set buffer pool size to 70% of RAM
SET GLOBAL innodb_buffer_pool_size = 10737418240; -- 10GB
```

#### Query Cache
- **Purpose**: Cache query results
- **Usefulness**: Limited in modern applications
- **Invalidation**: Complex cache invalidation
- **Alternative**: Application-level caching

### Connection Management

#### Connection Pooling
- **Purpose**: Reuse database connections
- **Benefits**: Reduced connection overhead
- **Configuration**: Pool size, timeout settings
- **Monitoring**: Pool utilization tracking

**Example Configuration**:
```python
# SQLAlchemy connection pool
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://user:pass@localhost/db',
    pool_size=20,
    max_overflow=30,
    pool_timeout=30,
    pool_recycle=3600
)
```

#### Connection Limits
- **Max connections**: Database connection limit
- **Application limits**: Application-side limits
- **Monitoring**: Connection usage tracking
- **Optimization**: Appropriate limit setting

## Performance Monitoring

### Key Metrics

#### Query Performance
- **Execution time**: Query duration
- **Rows examined**: Data processed
- **Index usage**: Index efficiency
- **Disk I/O**: Storage access patterns

#### System Metrics
- **CPU usage**: Processor utilization
- **Memory usage**: RAM consumption
- **Disk I/O**: Storage performance
- **Network I/O**: Network utilization

### Monitoring Tools

#### Database-Specific Tools
- **MySQL**: Slow query log, Performance Schema
- **PostgreSQL**: pg_stat_statements, EXPLAIN ANALYZE
- **MongoDB**: Profiler, explain() command
- **Redis**: SLOWLOG, INFO command

#### General Tools
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **New Relic**: APM and monitoring
- **Datadog**: Infrastructure monitoring

## Optimization Examples

### Index Optimization
```sql
-- Before: No index on user_id
EXPLAIN SELECT * FROM orders WHERE user_id = 123;
-- Result: Full table scan

-- After: Add index
CREATE INDEX idx_orders_user_id ON orders(user_id);
EXPLAIN SELECT * FROM orders WHERE user_id = 123;
-- Result: Index scan
```

### Query Optimization
```sql
-- Before: Inefficient subquery
SELECT u.name FROM users u
WHERE u.id IN (
    SELECT o.user_id FROM orders o 
    WHERE o.total > 1000
);

-- After: Efficient JOIN
SELECT DISTINCT u.name 
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.total > 1000;
```

### Configuration Optimization
```sql
-- PostgreSQL configuration
-- Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB

-- Connection settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'
```

## Best Practices

### Index Management
- **Monitor usage**: Track index effectiveness
- **Remove unused indexes**: Reduce maintenance overhead
- **Regular maintenance**: Rebuild fragmented indexes
- **Plan for growth**: Anticipate query patterns

### Query Optimization
- **Profile queries**: Identify slow operations
- **Test changes**: Validate improvements
- **Document patterns**: Share optimization techniques
- **Review regularly**: Continuous optimization

### Configuration Management
- **Monitor metrics**: Track performance indicators
- **Adjust gradually**: Make incremental changes
- **Test thoroughly**: Validate configuration changes
- **Document settings**: Maintain configuration history

---

**Key Takeaway**: Database optimization is an iterative process requiring continuous monitoring, analysis, and refinement based on actual usage patterns and performance requirements.
