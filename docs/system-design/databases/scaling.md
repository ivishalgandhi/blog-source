---
title: Database Scaling
description: Horizontal scaling, sharding, and replication strategies
sidebar_position: 32
---

# Database Scaling

> "Scaling strategies reveal the physical and economic limits of single-machine computation."

Database scaling is essential for handling growth in data volume, query load, and user traffic.

## Scaling Strategies

### Vertical Scaling (Scale-Up)
**Definition**: Increasing resources of a single server (CPU, RAM, storage).

**Advantages**:
- **Simple implementation**: No application changes
- **Consistent performance**: Single node operations
- **Strong consistency**: No distributed complexity
- **Easy maintenance**: Single system to manage

**Limitations**:
> "Vertical scaling is very limited."

- **Hardware limits**: Maximum server specifications
- **Cost escalation**: Exponential cost increases
- **Single point of failure**: No built-in redundancy
- **Downtime required**: Maintenance needs system restarts

**Use Cases**:
- Small to medium applications
- Simple scaling requirements
- Limited budget for complexity
- Strong consistency requirements

### Horizontal Scaling (Scale-Out)
**Definition**: Adding more servers to distribute load and data.

**Advantages**:
- **Unlimited scaling**: Add more servers as needed
- **Fault tolerance**: Redundant systems
- **Cost effective**: Commodity hardware
- **Geographic distribution**: Global deployment

**Challenges**:
- **Complexity**: Distributed system management
- **Consistency**: Eventual consistency models
- **Network overhead**: Inter-server communication
- **Application changes**: Distributed-aware code

## Sharding Strategies

### Range-Based Sharding
**Concept**: Divide data based on value ranges.

**Example**: User IDs 1-1000 on shard 1, 1001-2000 on shard 2.

**Advantages**:
- **Simple to understand**: Easy range queries
- **Predictable distribution**: Known data location
- **Efficient range queries**: Data locality

**Disadvantages**:
- **Hot spots**: Uneven distribution
- **Rebalancing complexity**: Moving ranges
- **Cross-shard queries**: Complex joins

### Hash-Based Sharding
**Concept**: Use hash function to determine shard location.

**Example**: shard_id = hash(user_id) % num_shards

**Advantages**:
- **Even distribution**: Balanced load
- **No hot spots**: Random distribution
- **Simple rebalancing**: Change hash function

**Disadvantages**:
- **Range queries difficult**: Data scattered
- **Rebalancing complexity**: Data migration
- **Hash function selection**: Critical for distribution

### Directory-Based Sharding
**Concept**: Use lookup table to determine shard location.

**Example**: Directory service maps user_id to shard_id.

**Advantages**:
- **Flexible mapping**: Dynamic allocation
- **Easy rebalancing**: Update directory
- **Complex queries**: Optimized routing

**Disadvantages**:
- **Single point of failure**: Directory dependency
- **Additional latency**: Lookup overhead
- **Directory maintenance**: Extra complexity

### Geographic Sharding
**Concept**: Distribute data based on geographic location.

**Example**: European users on EU servers, Asian users on Asian servers.

**Advantages**:
- **Latency optimization**: Data closer to users
- **Compliance**: Data residency requirements
- **Performance**: Reduced network latency

**Disadvantages**:
- **Complex routing**: Location-based queries
- **Uneven distribution**: Population density
- **Cross-region queries**: High latency

## Replication Strategies

### Master-Slave Replication
**Concept**: One master handles writes, multiple slaves handle reads.

**Write Flow**:
1. Client writes to master
2. Master updates local data
3. Master replicates to slaves
4. Slaves update their data

**Read Flow**:
1. Client reads from any slave
2. Slave returns cached data
3. Eventually consistent with master

**Advantages**:
- **Read scalability**: Multiple read replicas
- **Performance**: Read/write separation
- **Availability**: Slave failover capability
- **Backup**: Natural backup system

**Disadvantages**:
- **Write bottleneck**: Single master
- **Replication lag**: Eventual consistency
- **Complex failover**: Master election
- **Split brain**: Network partition issues

### Master-Master Replication
**Concept**: Multiple masters handle both reads and writes.

**Conflict Resolution**:
- **Last write wins**: Timestamp-based
- **Vector clocks**: Causal ordering
- **Application logic**: Custom resolution
- **Manual intervention**: Human resolution

**Advantages**:
- **Write scalability**: Multiple write nodes
- **High availability**: No single point of failure
- **Geographic distribution**: Local writes
- **Failover**: Natural redundancy

**Disadvantages**:
- **Conflict complexity**: Resolution overhead
- **Consistency challenges**: Concurrent writes
- **Implementation complexity**: Coordination required
- **Performance overhead**: Conflict detection

### Multi-Leader Replication
**Concept**: Each region has its own leader, replicates globally.

**Use Cases**:
- **Global applications**: Low latency writes
- **Offline capability**: Local writes sync later
- **Collaborative editing**: Real-time collaboration
- **Mobile applications**: Intermittent connectivity

## Implementation Examples

### Sharding Implementation
```python
class ShardedDatabase:
    def __init__(self, num_shards):
        self.shards = [Database() for _ in range(num_shards)]
        self.num_shards = num_shards
    
    def get_shard(self, key):
        shard_id = hash(key) % self.num_shards
        return self.shards[shard_id]
    
    def get(self, key):
        shard = self.get_shard(key)
        return shard.get(key)
    
    def set(self, key, value):
        shard = self.get_shard(key)
        return shard.set(key, value)
```

### Replication Configuration
```sql
-- Master configuration
CREATE USER 'replicator'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';

-- Slave configuration
CHANGE MASTER TO
    MASTER_HOST='master.example.com',
    MASTER_USER='replicator',
    MASTER_PASSWORD='password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=123;

START SLAVE;
```

## Consistency Models

### Strong Consistency
- **Linearizability**: Operations appear atomic
- **Sequential consistency**: All operations in order
- **High overhead**: Coordination required
- **Use Cases**: Financial systems, inventory

### Eventual Consistency
- **Converges over time**: All replicas eventually agree
- **High availability**: Always writable
- **Low latency**: Local operations
- **Use Cases**: Social media, caching

### Causal Consistency
- **Preserves causality**: Related operations ordered
- **Partial ordering**: Only related operations
- **Balanced approach**: Performance + some guarantees
- **Use Cases**: Collaborative applications

## Best Practices

### Sharding Best Practices
- **Choose appropriate key**: Even distribution
- **Plan for rebalancing**: Future growth
- **Monitor distribution**: Prevent hot spots
- **Test failure scenarios**: Resilience validation

### Replication Best Practices
- **Monitor lag**: Replication delay tracking
- **Plan failover**: Automatic recovery
- **Test consistency**: Data validation
- **Document procedures**: Operational guidelines

### General Scaling Best Practices
- **Start simple**: Add complexity as needed
- **Monitor performance**: Identify bottlenecks
- **Plan capacity**: Proactive scaling
- **Test thoroughly**: Load and failure testing

---

**Key Takeaway**: Database scaling requires careful planning of sharding and replication strategies, balancing consistency, availability, and complexity based on application requirements.
