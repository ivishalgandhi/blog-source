---
title: Load Balancing
description: Load balancer algorithms and traffic distribution strategies
sidebar_position: 11
---

# Load Balancing

> "Load balancers are perhaps the most popular use cases of proxy servers."

Load balancers distribute user requests evenly across multiple backend servers, ensuring no single server becomes overwhelmed.

## Load Balancing Algorithms

### Round Robin
Distributes requests sequentially to each server in rotation.

**Pros:**
- Simple to implement
- Equal distribution
- Works well for identical servers

**Cons:**
- Ignores server capacity
- No session persistence
- Doesn't consider current load

### Least Connections
Sends requests to the server with the fewest active connections.

**Pros:**
- Considers actual server load
- Better for varying request durations
- More efficient resource utilization

**Cons:**
- Requires connection tracking
- More complex implementation
- May not consider response times

### IP Hash
Uses client IP address to determine server selection.

**Pros:**
- Session persistence
- Predictable distribution
- Cache-friendly

**Cons:**
- Uneven distribution with few clients
- Problems with NAT networks
- Can overload specific servers

### Consistent Hashing
> "Consistent hashing ensures a client consistently connects to the same server."

**Mechanism:**
- Maps both servers and clients to a hash ring
- Each client is assigned to the next server clockwise
- Minimal remapping when servers are added/removed

**Benefits:**
- Session persistence
- Even distribution
- Minimal disruption during scaling

## Load Balancer Types

### Layer 4 (Transport Layer)
- Operates at TCP/UDP level
- Fast and efficient
- Limited visibility into application data

### Layer 7 (Application Layer)
- Operates at HTTP level
- Can inspect request content
- More flexible but slower

## High Availability Setup

### Active-Passive Configuration
- Primary load balancer handles all traffic
- Secondary takes over on failure
- Requires health monitoring and failover

### Active-Active Configuration
- Multiple load balancers handle traffic
- DNS round-robin for distribution
- More complex but no single point of failure

## Implementation Examples

### Hardware Load Balancers
- **F5 BIG-IP**: Enterprise-grade solution
- **Citrix NetScaler**: Advanced features
- **Cisco ACE**: Network integration

### Software Load Balancers
- **NGINX**: High performance, feature-rich
- **HAProxy**: Reliable, configuration-focused
- **Envoy**: Modern, cloud-native

### Cloud Load Balancers
- **AWS ELB/ALB**: Integrated with AWS services
- **Google Cloud Load Balancer**: Global capabilities
- **Azure Load Balancer**: Microsoft ecosystem

## Health Checks

### Types of Health Checks
- **TCP connect**: Basic connectivity test
- **HTTP request**: Application-level check
- **Custom scripts**: Complex validation logic

### Health Check Configuration
- **Check interval**: Frequency of health checks
- **Timeout**: Maximum response time
- **Unhealthy threshold**: Failures before removal
- **Healthy threshold**: Successes before addition

## Session Persistence

### Cookie-based Persistence
- Server sets special cookie
- Load balancer routes based on cookie value
- Works with HTTP clients

### Source IP Persistence
- Routes based on client IP address
- Works with non-HTTP protocols
- Problems with NAT and mobile clients

### SSL Session Persistence
- Uses SSL session ID
- Limited to HTTPS connections
- Not widely supported

## Best Practices

### Performance Optimization
- Enable connection pooling
- Use HTTP/2 where possible
- Implement SSL termination
- Optimize health check frequency

### Security Considerations
- Implement rate limiting
- Use Web Application Firewall (WAF)
- Enable DDoS protection
- Regular security updates

### Monitoring and Logging
- Track request distribution
- Monitor server health
- Log failover events
- Set up alerting for anomalies

## Configuration Example

### NGINX Load Balancer
```nginx
upstream backend {
    least_conn;
    server backend1.example.com weight=3;
    server backend2.example.com;
    server backend3.example.com backup;
    
    keepalive 32;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
    }
}
```

---

**Key Takeaway**: Load balancing is essential for scalability and reliability, but the right algorithm and configuration depend on your specific use case and requirements.
