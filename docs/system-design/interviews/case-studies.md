---
title: Design Case Studies
description: Complete system design examples with detailed solutions
sidebar_position: 52
---

# System Design Case Studies

This section provides complete system design examples that demonstrate the application of design principles and patterns.

## Case Study 1: Design a URL Shortening Service

### Requirements
- **Functional**:
  - Shorten long URLs to compact format
  - Redirect short URLs to original URLs
  - Support custom short URLs
  - Provide analytics and statistics

- **Non-functional**:
  - High availability (99.9% uptime)
  - Low latency (&lt;100ms redirection)
  - Handle 100M URLs, 1B clicks/month
  - Global distribution

### System Design

#### High-Level Architecture
```
Client → Load Balancer → API Servers → Cache → Database
                     ↓
                 Analytics Pipeline
```

#### URL Generation Strategy
- **Base62 encoding**: 0-9, a-z, A-Z characters
- **Counter-based**: Sequential ID generation
- **Distributed ID**: Snowflake algorithm
- **Collision handling**: Retry with new ID

#### Database Schema
```sql
CREATE TABLE urls (
    id BIGINT PRIMARY KEY,
    short_url VARCHAR(10) UNIQUE,
    long_url TEXT NOT NULL,
    user_id BIGINT,
    created_at TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE TABLE analytics (
    id BIGINT PRIMARY KEY,
    url_id BIGINT REFERENCES urls(id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    country VARCHAR(2),
    clicked_at TIMESTAMP
);
```

#### API Design
```python
# POST /api/v1/urls
{
    "long_url": "https://example.com/very/long/path",
    "custom_alias": "mylink"  # optional
}

# Response
{
    "short_url": "https://short.ly/abc123",
    "long_url": "https://example.com/very/long/path"
}

# GET /{short_url}
# HTTP 301 redirect to long_url
```

### Scalability Considerations

#### Caching Strategy
- **Redis cache**: Popular URLs (80/20 rule)
- **CDN caching**: Edge server redirects
- **TTL settings**: 1 hour for analytics, 24 hours for URLs

#### Database Sharding
- **Shard key**: URL ID hash
- **Replication**: Master-slave for reads
- **Partitioning**: Geographic distribution

#### Load Balancing
- **Round-robin**: Distribute API requests
- **Geographic routing**: Route to nearest server
- **Health checks**: Monitor server availability

### Implementation Example

#### URL Generation Service
```python
import redis
import hashlib
import base62

class URLShortener:
    def __init__(self, redis_client, db_client):
        self.redis = redis_client
        self.db = db_client
        self.counter = 1000000  # Starting ID
    
    def generate_short_url(self, long_url, custom_alias=None):
        if custom_alias:
            if self.is_alias_taken(custom_alias):
                raise ValueError("Custom alias already taken")
            short_code = custom_alias
        else:
            # Generate sequential ID
            self.counter += 1
            short_code = base62.encode(self.counter)
        
        # Store in database
        url_id = self.db.create_url(short_code, long_url)
        
        # Cache the mapping
        self.redis.setex(f"url:{short_code}", 3600, long_url)
        
        return f"https://short.ly/{short_code}"
    
    def get_long_url(self, short_code):
        # Check cache first
        long_url = self.redis.get(f"url:{short_code}")
        if long_url:
            return long_url.decode()
        
        # Check database
        long_url = self.db.get_long_url(short_code)
        if long_url:
            # Cache for future requests
            self.redis.setex(f"url:{short_code}", 3600, long_url)
            return long_url
        
        return None
```

#### Analytics Service
```python
class AnalyticsService:
    def __init__(self, db_client, event_producer):
        self.db = db_client
        self.event_producer = event_producer
    
    def track_click(self, short_code, request_data):
        # Store click event
        click_data = {
            'short_code': short_code,
            'ip_address': request_data['ip'],
            'user_agent': request_data['user_agent'],
            'country': request_data['country'],
            'timestamp': datetime.utcnow()
        }
        
        # Send to analytics pipeline
        self.event_producer.send('url_clicks', click_data)
        
        # Update real-time counters
        self.db.increment_click_count(short_code)
```

---

## Case Study 2: Design a Chat Application

### Requirements
- **Functional**:
  - Real-time messaging
  - Group conversations
  - Message history
  - Online presence
  - File sharing

- **Non-functional**:
  - Low latency (&lt;50ms message delivery)
  - High availability (99.99% uptime)
  - Support 10M concurrent users
  - Message persistence

### System Design

#### Architecture Overview
```
Client → WebSocket Gateway → Message Queue → Chat Service → Database
                     ↓              ↓
              Presence Service   Analytics
                     ↓
              Push Notification Service
```

#### Message Flow
1. **Client sends message** via WebSocket
2. **Gateway validates** and forwards to message queue
3. **Chat service processes** and stores message
4. **Presence service updates** user status
5. **Push notifications** sent to offline users
6. **Clients receive** real-time updates

#### Database Design
```sql
-- Users table
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100),
    status ENUM('online', 'offline', 'away'),
    last_seen TIMESTAMP
);

-- Conversations table
CREATE TABLE conversations (
    id BIGINT PRIMARY KEY,
    type ENUM('private', 'group'),
    name VARCHAR(100),
    created_at TIMESTAMP
);

-- Messages table (sharded by conversation_id)
CREATE TABLE messages (
    id BIGINT PRIMARY KEY,
    conversation_id BIGINT,
    sender_id BIGINT,
    content TEXT,
    message_type ENUM('text', 'image', 'file'),
    created_at TIMESTAMP,
    INDEX idx_conversation_created (conversation_id, created_at)
);

-- Conversation participants
CREATE TABLE conversation_participants (
    conversation_id BIGINT,
    user_id BIGINT,
    role ENUM('admin', 'member'),
    joined_at TIMESTAMP,
    PRIMARY KEY (conversation_id, user_id)
);
```

#### WebSocket Connection Management
```python
class ConnectionManager:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.connections = {}  # user_id -> websocket
    
    async def connect(self, user_id, websocket):
        self.connections[user_id] = websocket
        await self.redis.sadd(f"online_users", user_id)
        await self.update_presence(user_id, 'online')
    
    async def disconnect(self, user_id):
        if user_id in self.connections:
            del self.connections[user_id]
        await self.redis.srem(f"online_users", user_id)
        await self.update_presence(user_id, 'offline')
    
    async def send_message(self, recipient_id, message):
        if recipient_id in self.connections:
            await self.connections[recipient_id].send(message)
        else:
            # User offline, send push notification
            await self.send_push_notification(recipient_id, message)
```

#### Message Service
```python
class MessageService:
    def __init__(self, db_client, queue_client, presence_service):
        self.db = db_client
        self.queue = queue_client
        self.presence = presence_service
    
    async def send_message(self, sender_id, conversation_id, content):
        # Create message
        message = await self.db.create_message(
            conversation_id=conversation_id,
            sender_id=sender_id,
            content=content
        )
        
        # Get conversation participants
        participants = await self.db.get_conversation_participants(
            conversation_id
        )
        
        # Send to online users
        for participant in participants:
            if participant != sender_id:
                if await self.presence.is_online(participant):
                    await self.queue.publish(f"user:{participant}", message)
                else:
                    await self.queue.publish(f"notifications:{participant}", message)
        
        return message
```

### Scalability Strategies

#### Horizontal Scaling
- **WebSocket gateways**: Multiple instances with sticky sessions
- **Message queues**: Kafka for high throughput
- **Database sharding**: By conversation_id
- **Caching**: Redis for online status and recent messages

#### Performance Optimization
- **Message batching**: Group multiple messages
- **Connection pooling**: Reuse database connections
- **CDN for media**: File sharing optimization
- **Compression**: Reduce message size

---

## Case Study 3: Design a Video Streaming Platform

### Requirements
- **Functional**:
  - Video upload and processing
  - Adaptive bitrate streaming
  - Recommendation engine
  - User comments and ratings
  - Live streaming

- **Non-functional**:
  - High bandwidth optimization
  - Low latency streaming
  - Global content delivery
  - Support 1M concurrent viewers

### System Design

#### Architecture Components
```
Upload Service → Processing Pipeline → Storage → CDN → Client
                     ↓
              Transcoding Service
                     ↓
              Recommendation Engine
                     ↓
              Analytics Service
```

#### Video Processing Pipeline
1. **Upload**: User uploads original video
2. **Validation**: Check format, size, duration
3. **Transcoding**: Convert to multiple bitrates
4. **Thumbnail generation**: Create preview images
5. **Metadata extraction**: Duration, resolution, codec
6. **CDN upload**: Distribute to edge servers

#### Adaptive Bitrate Streaming
```python
class StreamingService:
    def __init__(self, cdn_client, analytics_client):
        self.cdn = cdn_client
        self.analytics = analytics_client
    
    def get_playlist(self, video_id, user_quality='auto'):
        # Get available bitrates for video
        bitrates = self.get_video_bitrates(video_id)
        
        if user_quality == 'auto':
            # Select bitrate based on network conditions
            bandwidth = self.estimate_bandwidth()
            selected_quality = self.select_optimal_quality(bitrates, bandwidth)
        else:
            selected_quality = user_quality
        
        # Generate HLS/DASH playlist
        playlist = self.generate_playlist(video_id, selected_quality)
        
        # Track quality selection
        self.analytics.track_quality_selection(video_id, selected_quality)
        
        return playlist
    
    def select_optimal_quality(self, bitrates, bandwidth):
        # Select highest quality that fits bandwidth
        suitable_qualities = [
            quality for quality in bitrates 
            if quality['bitrate'] < bandwidth * 0.8  # 80% of available bandwidth
        ]
        
        return suitable_qualities[-1] if suitable_qualities else bitrates[0]
```

#### Recommendation Engine
```python
class RecommendationService:
    def __init__(self, db_client, ml_model):
        self.db = db_client
        self.model = ml_model
    
    def get_recommendations(self, user_id, limit=20):
        # Get user watch history
        watch_history = self.db.get_user_watch_history(user_id)
        
        # Get collaborative filtering recommendations
        collaborative_recs = self.model.collaborative_filtering(user_id)
        
        # Get content-based recommendations
        content_recs = self.model.content_based_filtering(watch_history)
        
        # Get trending videos
        trending = self.db.get_trending_videos()
        
        # Combine and rank recommendations
        recommendations = self.combine_recommendations(
            collaborative_recs, content_recs, trending
        )
        
        return recommendations[:limit]
    
    def update_user_preferences(self, user_id, video_id, interaction_type):
        # Update user preference model
        self.model.update_user_preferences(
            user_id, video_id, interaction_type
        )
        
        # Trigger model retraining if needed
        if self.should_retrain():
            self.model.retrain()
```

### Performance Optimization

#### CDN Strategy
- **Geographic distribution**: Edge servers worldwide
- **Cache hierarchy**: Multiple cache levels
- **Cache invalidation**: Smart cache updates
- **Origin protection**: Shield origin servers

#### Transcoding Optimization
- **Parallel processing**: Multiple quality levels
- **GPU acceleration**: Hardware encoding
- **Adaptive encoding**: Content-aware optimization
- **Cost optimization**: Spot instances for batch jobs

---

## Interview Tips

### Communication Strategies
- **Think aloud**: Explain your reasoning
- **Ask questions**: Clarify requirements
- **Draw diagrams**: Visualize architecture
- **Discuss trade-offs**: Justify decisions

### Time Management
- **Requirements**: 5-10 minutes
- **High-level design**: 10-15 minutes
- **Deep dive**: 15-20 minutes
- **Questions**: 5-10 minutes

### Common Questions to Ask
- "What's the expected scale?"
- "What are the performance requirements?"
- "What's the budget constraint?"
- "Should we optimize for cost or performance?"

---

**Key Takeaway**: System design case studies demonstrate how to apply design principles to real-world problems, considering requirements, constraints, and trade-offs to create robust solutions.
