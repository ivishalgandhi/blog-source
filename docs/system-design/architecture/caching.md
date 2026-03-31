---
title: Caching Strategies
description: Multi-layer caching and content delivery networks
sidebar_position: 12
---

# Caching

> "The purpose of a cache is to reduce the average time to access data."

Caching stores copies of data in temporary storage to serve future requests faster. It's the universal performance lever applied at every layer from CPU to continent.

## Cache Fundamentals

### Cache Hit vs Cache Miss
- **Cache Hit**: Requested data is found in cache
- **Cache Miss**: Data not found, must fetch from source
- **Hit Ratio**: Percentage of requests served from cache

### Cache Locality
- **Temporal locality**: Recently accessed data likely to be accessed again
- **Spatial locality**: Data near recently accessed data likely to be accessed

## Cache Eviction Policies

### LRU (Least Recently Used)
Removes the least recently used items when cache is full.

**Pros:**
- Good temporal locality
- Widely implemented
- Predictable performance

**Cons:**
- Requires timestamp tracking
- Memory overhead
- Not optimal for all patterns

### LFU (Least Frequently Used)
Removes items with lowest access frequency.

**Pros:**
- Good for stable access patterns
- Keeps popular items longer
- Better for read-heavy workloads

**Cons:**
- Complex implementation
- Memory overhead for counters
- Slow to adapt to changing patterns

### FIFO (First In, First Out)
Removes items in insertion order.

**Pros:**
- Simple implementation
- Low overhead
- Predictable behavior

**Cons:**
- Ignores access patterns
- May remove frequently used items
- Poor temporal locality

## Caching Layers

### Browser Caching
**Location**: Client browser
**Content**: Static assets, API responses
**Control**: Cache-Control headers, ETags

```http
Cache-Control: max-age=3600, public
ETag: "abc123"
```

### CDN Caching
**Location**: Edge servers globally
**Content**: Static assets, dynamic content
**Benefits**: Reduced latency, geographic distribution

### Application Caching
**Location**: Application memory
**Content**: Computed results, database queries
**Technologies**: Redis, Memcached, in-memory

### Database Caching
**Location**: Database buffer pool
**Content**: Query results, index pages
**Optimization**: Buffer pool tuning, query cache

## Cache Invalidation Strategies

### Time-based Expiration
- **TTL (Time To Live)**: Fixed expiration time
- **Absolute expiration**: Specific timestamp
- **Sliding expiration**: Reset on access

### Event-based Invalidation
- **Write-through**: Update cache and database simultaneously
- **Write-behind**: Update cache immediately, database later
- **Cache-aside**: Application manages cache explicitly

### Manual Invalidation
- **Explicit cache clearing**
- **Tag-based invalidation**
- **Dependency tracking**

## Content Delivery Networks (CDNs)

### CDN Types
- **Pull-based**: Content fetched on first request
- **Push-based**: Content pre-loaded to edge servers

### CDN Benefits
- **Reduced latency**: Content closer to users
- **Bandwidth savings**: Offload from origin server
- **Improved reliability**: Distributed infrastructure
- **DDoS protection**: Absorb traffic spikes

### Major CDN Providers
- **Cloudflare**: Security-focused, global network
- **AWS CloudFront**: AWS ecosystem integration
- **Google Cloud CDN**: Google infrastructure
- **Fastly**: Real-time configuration, edge computing

## Caching Patterns

### Cache-Aside (Lazy Loading)
1. Application checks cache
2. If miss, fetch from database
3. Populate cache with data
4. Return data to client

**Pros:**
- Simple implementation
- Cache only contains needed data
- Handles cache failures gracefully

**Cons:**
- Cache miss penalty
- Potential for stale data
- Thundering herd problem

### Read-Through Cache
1. Application always reads from cache
2. Cache handles database fetch on miss
3. Cache manages population and updates

**Pros:**
- Simplified application code
- Consistent cache behavior
- Better cache hit ratio

**Cons:**
- More complex cache implementation
- Cache becomes critical component
- Limited flexibility

### Write-Through Cache
1. Application writes to cache
2. Cache immediately writes to database
3. Returns success after both complete

**Pros:**
- Data consistency guaranteed
- No stale data in cache
- Simple recovery process

**Cons:**
- Higher write latency
- Increased database load
- Reduced write throughput

### Write-Behind Cache
1. Application writes to cache
2. Cache acknowledges immediately
3. Cache writes to database asynchronously

**Pros:**
- Low write latency
- High write throughput
- Can batch database writes

**Cons:**
- Risk of data loss
- Complex recovery logic
- Potential for inconsistency

## Implementation Examples

### Redis Caching
```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, db=0)

def get_user(user_id):
    # Check cache first
    cached_user = r.get(f'user:{user_id}')
    if cached_user:
        return json.loads(cached_user)
    
    # Cache miss - fetch from database
    user = db.get_user(user_id)
    
    # Cache the result
    r.setex(f'user:{user_id}', 3600, json.dumps(user))
    
    return user
```

### HTTP Caching Headers
```http
# Strong caching
Cache-Control: public, max-age=31536000

# Validation-based caching
Cache-Control: no-cache
ETag: "abc123"

# No caching
Cache-Control: no-store, must-revalidate
```

## Best Practices

### Cache Key Design
- **Descriptive names**: Clear purpose identification
- **Versioning**: Handle schema changes
- **Hierarchy**: Organize related keys
- **TTL strategy**: Appropriate expiration times

### Monitoring and Metrics
- **Hit ratio**: Measure cache effectiveness
- **Eviction rate**: Monitor cache pressure
- **Response times**: Track performance impact
- **Memory usage**: Prevent cache overflow

### Common Pitfalls
- **Cache stampede**: Many simultaneous misses
- **Stale data**: Inconsistent cache state
- **Memory leaks**: Unbounded cache growth
- **Single point of failure**: Cache dependency

---

**Key Takeaway**: Effective caching requires understanding access patterns, choosing appropriate eviction policies, and implementing proper invalidation strategies across multiple system layers.
