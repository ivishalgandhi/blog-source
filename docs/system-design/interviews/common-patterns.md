---
title: Common Interview Patterns
description: Frequently asked system design topics and solution patterns
sidebar_position: 51
---

# Common Interview Patterns

System design interviews often follow predictable patterns. Understanding these common topics and solution approaches is key to success.

## Interview Framework

### Step 1: Requirements Clarification
- **Functional requirements**: What the system must do
- **Non-functional requirements**: Performance, scalability, reliability
- **Constraints**: Budget, timeline, team size
- **Assumptions**: Document and validate assumptions

### Step 2: System Design
- **High-level architecture**: Major components and interactions
- **Data model**: Database schema and relationships
- **API design**: Key endpoints and data flow
- **Scalability approach**: Horizontal vs vertical scaling

### Step 3: Deep Dive
- **Component design**: Detailed component architecture
- **Data flow**: Request/response lifecycle
- **Bottleneck analysis**: Identify and address bottlenecks
- **Failure scenarios**: Error handling and recovery

### Step 4: Trade-offs Discussion
- **Technology choices**: Justify your selections
- **Performance vs complexity**: Balance competing requirements
- **Cost considerations**: Infrastructure and operational costs
- **Future evolution**: How the system can grow

## Common Question Types

### Social Media Platforms
**Examples**: Twitter, Facebook, Instagram
**Key Challenges**: 
- High write throughput
- Timeline generation
- Feed ranking
- Real-time notifications

**Solution Patterns**:
- **Write-optimized databases**: Cassandra, DynamoDB
- **Timeline generation**: Fan-out on write
- **Feed ranking**: Machine learning pipelines
- **Real-time updates**: WebSockets, push notifications

### URL Shortening Services
**Examples**: Bitly, TinyURL
**Key Challenges**:
- High read/write ratio
- Unique ID generation
- Analytics tracking
- Custom URLs

**Solution Patterns**:
- **Base62 encoding**: Compact URL representation
- **Distributed ID generation**: Snowflake, UUID
- **Caching**: Redis for popular URLs
- **Analytics**: Event processing pipelines

### Messaging Systems
**Examples**: WhatsApp, Slack
**Key Challenges**:
- Real-time delivery
- Message persistence
- Offline support
- Group messaging

**Solution Patterns**:
- **WebSocket connections**: Real-time communication
- **Message queues**: RabbitMQ, Kafka
- **Push notifications**: Firebase, APNs
- **Presence tracking**: Redis, databases

### Video Streaming Platforms
**Examples**: YouTube, Netflix
**Key Challenges**:
- High bandwidth requirements
- Content delivery optimization
- Recommendation algorithms
- Digital rights management

**Solution Patterns**:
- **CDN distribution**: Edge server caching
- **Adaptive bitrate**: Multiple quality levels
- **Recommendation engines**: Machine learning
- **DRM**: Content encryption and licensing

### Ride-sharing Services
**Examples**: Uber, Lyft
**Key Challenges**:
- Real-time location tracking
- Driver-rider matching
- Surge pricing
- Payment processing

**Solution Patterns**:
- **Geospatial indexing**: Quad trees, H3
- **Real-time matching**: WebSocket, push notifications
- **Dynamic pricing**: Algorithmic pricing models
- **Payment integration**: Stripe, PayPal APIs

## Design Patterns

### Caching Patterns
- **Cache-aside**: Application manages cache
- **Read-through**: Cache manages reads
- **Write-through**: Cache manages writes
- **Write-behind**: Asynchronous writes

### Database Patterns
- **Master-slave**: Read scaling
- **Sharding**: Horizontal scaling
- **Eventual consistency**: Distributed systems
- **Polyglot persistence**: Multiple databases

### Communication Patterns
- **Request-response**: Traditional HTTP
- **Event-driven**: Message queues
- **Streaming**: Real-time data
- **Pub-sub**: Decoupled communication

### Scalability Patterns
- **Load balancing**: Traffic distribution
- **Horizontal scaling**: Adding more machines
- **Microservices**: Service decomposition
- **Serverless**: Function-based scaling

## Common Technologies

### Databases
- **SQL**: PostgreSQL, MySQL
- **NoSQL**: MongoDB, Cassandra, DynamoDB
- **In-memory**: Redis, Memcached
- **Search**: Elasticsearch, Solr

### Message Queues
- **RabbitMQ**: Traditional messaging
- **Kafka**: High-throughput streaming
- **SQS**: Cloud-based queuing
- **Redis Pub/Sub**: Simple pub-sub

### Caching
- **Redis**: In-memory data store
- **Memcached**: Simple caching
- **CDN**: Edge caching
- **Application cache**: Local caching

### Load Balancers
- **NGINX**: Web server and balancer
- **HAProxy**: Dedicated balancer
- **AWS ALB**: Cloud-based balancing
- **Envoy**: Modern proxy

## Estimation Techniques

### Capacity Planning
- **QPS estimation**: Queries per second
- **Storage estimation**: Data growth projections
- **Bandwidth estimation**: Network requirements
- **Memory estimation**: Cache and application memory

### Performance Metrics
- **Latency**: Response time requirements
- **Throughput**: Requests per second
- **Availability**: Uptime requirements
- **Consistency**: Data consistency needs

### Cost Estimation
- **Infrastructure costs**: Servers, storage, network
- **Operational costs**: Monitoring, maintenance
- **Scaling costs**: Growth projections
- **Optimization opportunities**: Cost reduction

## Common Pitfalls

### Requirements Misunderstanding
- **Solution**: Ask clarifying questions
- **Example**: "What's the expected scale?"
- **Impact**: Wrong architecture choices

### Over-engineering
- **Solution**: Start simple, evolve complexity
- **Example**: Don't use distributed systems for simple problems
- **Impact**: Unnecessary complexity and cost

### Ignoring Trade-offs
- **Solution**: Explicitly discuss trade-offs
- **Example**: "We choose consistency over availability"
- **Impact**: Missing key design considerations

### No Failure Analysis
- **Solution**: Consider failure scenarios
- **Example**: "What if the database goes down?"
- **Impact**: Unreliable system design

## Preparation Tips

### Study Common Systems
- **Social media**: Twitter, Facebook
- **E-commerce**: Amazon, eBay
- **Streaming**: YouTube, Netflix
- **Messaging**: WhatsApp, Slack

### Practice Framework
- **Time management**: 45-60 minutes per problem
- **Whiteboard practice**: Draw diagrams clearly
- **Communication**: Explain your thought process
- **Questions**: Ask clarifying questions

### Technical Knowledge
- **Databases**: SQL vs NoSQL, scaling
- **Networking**: HTTP, TCP/IP, DNS
- **Caching**: Strategies and patterns
- **Load balancing**: Algorithms and configurations

---

**Key Takeaway**: System design interviews test your ability to think systematically about complex problems, make informed trade-offs, and communicate your design decisions clearly.
