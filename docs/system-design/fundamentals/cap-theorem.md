---
title: CAP Theorem
description: Understanding consistency, availability, and partition tolerance trade-offs
sidebar_position: 5
---

# The CAP Theorem

> "The CAP theorem states that you can only have two of these three: consistency, availability, and partition tolerance."

Also known as Brewer's Theorem, the CAP theorem formalizes the fundamental trade-offs in distributed systems.

## The Three Properties

### Consistency (C)
All nodes see the same data at the same time. A read operation returns the most recent write for all clients.

**Characteristics:**
- Strong consistency guarantees
- Single-copy semantics
- Higher latency for distributed operations

### Availability (A)
Every request receives a response (success or failure), without guarantee that it contains the most recent write.

**Characteristics:**
- Always responsive
- No timeouts or errors
- Potential for stale data

### Partition Tolerance (P)
The system continues to operate despite arbitrary message loss or failure of part of the system.

**Characteristics:**
- Network failures are expected
- System remains operational
- Inevitable in distributed systems

## The Trade-Off Triangle

```
    Consistency
       / \
      /   \
     /     \
CP  +-------+  AP
     \     /
      \   /
       \ /
    Partition Tolerance
```

### CP Systems (Consistency + Partition Tolerance)
**Choose when:** Data accuracy is critical
- Sacrifice availability during partitions
- Examples: Banking systems, inventory management
- Technologies: HBase, MongoDB (with strong consistency)

### AP Systems (Availability + Partition Tolerance)
**Choose when:** System responsiveness is critical
- Sacrifice consistency during partitions
- Examples: Social media feeds, caching systems
- Technologies: Cassandra, DynamoDB, CouchDB

### CA Systems (Consistency + Availability)
**Choose when:** Network partitions are impossible
- Not practical for distributed systems
- Examples: Single-node databases, traditional RDBMS
- Technologies: PostgreSQL, MySQL (single instance)

## Practical Implications

### Network Partitions are Inevitable
In real distributed systems, network partitions will occur. Therefore, the real choice is between CP and AP.

### Business Requirements Drive the Choice
- **Financial systems**: Must choose consistency
- **Social applications**: Often choose availability
- **Caching systems**: Typically choose availability

## Design Patterns

### Consistency Patterns
- **Strong consistency**: Linearizability, serializability
- **Eventual consistency**: Converge over time
- **Read-your-writes**: User sees their own writes

### Availability Patterns
- **Replication**: Multiple copies of data
- **Quorum writes**: Majority acknowledgment
- **Conflict resolution**: Last-write-wins, vector clocks

## Real-World Examples

### Google Spanner (CP)
- Globally distributed database
- Strong consistency guarantees
- Uses atomic clocks for synchronization

### Amazon DynamoDB (AP)
- Highly available key-value store
- Eventual consistency model
- Tunable consistency options

### Apache Cassandra (AP)
- Masterless architecture
- No single point of failure
- Configurable consistency levels

## Making the Right Choice

### Questions to Ask
1. What happens if users see stale data?
2. What happens if the system becomes unavailable?
3. How often do network partitions occur?
4. What are the business costs of each failure mode?

### Decision Framework
- **High cost of inconsistency**: Choose CP
- **High cost of unavailability**: Choose AP
- **Critical operations**: CP, non-critical: AP

---

**Key Takeaway**: The CAP theorem is not a limitation to be overcome but a reality to be embraced. Understanding these trade-offs is fundamental to distributed system design.
