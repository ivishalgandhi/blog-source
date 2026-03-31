---
title: Scalability
description: Understanding vertical and horizontal scaling strategies
sidebar_position: 3
---

# Scalability

## Vertical Scaling

**Definition**: Improving a single server's capabilities by adding more resources (CPU, RAM, storage).

### Characteristics
- Simple to implement
- Limited by maximum hardware capabilities
- Single point of failure remains

### Limitations
> "Vertical scaling is very limited."

- Physical hardware constraints
- Cost increases exponentially
- No fault tolerance improvement

## Horizontal Scaling

**Definition**: Adding more machines to distribute load across multiple servers.

### Strategies

#### Sharding
Splits data into smaller chunks distributed across multiple servers:
- **Range-based sharding**: Data divided by value ranges
- **Directory-based sharding**: Lookup table determines data location
- **Geographic sharding**: Data distributed by geographic region

#### Replication
Keeps copies of data on multiple servers for high availability:
- **Master-slave replication**: One writable master, multiple read-only slaves
- **Multi-master replication**: Multiple writable masters with conflict resolution

### Benefits
- Nearly unlimited scaling potential
- Built-in fault tolerance
- Better geographic distribution

## Choosing the Right Strategy

### Consider Vertical Scaling When:
- Simple applications with predictable growth
- Limited budget for infrastructure
- Applications that don't require high availability

### Consider Horizontal Scaling When:
- Large-scale applications with unpredictable growth
- High availability requirements
- Geographic distribution needs

## Implementation Patterns

### Database Scaling
- **Read replicas**: Separate read and write operations
- **Connection pooling**: Manage and reuse database connections
- **Indexing**: Speed up frequently accessed columns

### Application Scaling
- **Stateless design**: Enables easy load distribution
- **Session externalization**: Store sessions in external systems
- **Microservices**: Break down monolithic applications

---

**Key Takeaway**: While vertical scaling is simpler, horizontal scaling provides the foundation for truly resilient, large-scale systems.
