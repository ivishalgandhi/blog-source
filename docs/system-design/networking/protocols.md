---
title: Network Protocols
description: Understanding TCP, UDP, HTTP, WebSockets, and other protocols
sidebar_position: 21
---

# Network Protocols

> "TCP is like a delivery guy who makes sure that your package not only arrives but also checks that nothing is missing."

Network protocols are standardized rules for communication between devices. Each protocol is optimized for specific use cases and requirements.

## Transport Layer Protocols

### TCP (Transmission Control Protocol)
**Characteristics**:
- Connection-oriented
- Reliable, ordered delivery
- Flow control and congestion control
- Three-way handshake for connection establishment

**Use Cases**:
- Web browsing (HTTP/HTTPS)
- Email (SMTP, IMAP)
- File transfer (FTP)
- Database connections

**Trade-offs**:
- Higher latency due to connection setup
- More overhead for reliability
- Not suitable for real-time applications

### UDP (User Datagram Protocol)
**Characteristics**:
- Connectionless
- Fast but unreliable
- No ordering guarantees
- No flow control

**Use Cases**:
- Video streaming
- Online gaming
- DNS queries
- VoIP applications

**Trade-offs**:
- No delivery guarantees
- No ordering
- Application must handle reliability

## Application Layer Protocols

### HTTP/HTTPS
> "HTTP is a request-response protocol but imagine it as a conversation with no memory."

**HTTP Characteristics**:
- Stateless protocol
- Request-response model
- Text-based (HTTP/1.1) or binary (HTTP/2)
- Port 80 (HTTP), 443 (HTTPS)

**HTTP Methods**:
- **GET**: Retrieve data (idempotent)
- **POST**: Create new resource
- **PUT**: Update entire resource
- **PATCH**: Partial update
- **DELETE**: Remove resource

**Status Codes**:
- **2xx**: Success (200 OK, 201 Created)
- **3xx**: Redirection (301, 302)
- **4xx**: Client errors (400, 404, 403)
- **5xx**: Server errors (500, 502, 503)

### WebSockets
> "Web sockets provide a two-way communication channel over a single long-lived connection."

**Characteristics**:
- Full-duplex communication
- Persistent connection
- Low latency
- Real-time data exchange

**Use Cases**:
- Chat applications
- Live notifications
- Real-time dashboards
- Collaborative editing

**Handshake Process**:
1. Client sends HTTP upgrade request
2. Server responds with 101 Switching Protocols
3. WebSocket connection established
4. Bi-directional communication begins

### SMTP (Simple Mail Transfer Protocol)
**Characteristics**:
- Text-based protocol
- Push-based email delivery
- Port 25 (SMTP), 587 (submission), 465 (SMTPS)

**Email Flow**:
1. Sender client → SMTP server
2. SMTP server → Recipient SMTP server
3. Recipient retrieves via IMAP/POP3

### SSH (Secure Shell)
**Characteristics**:
- Encrypted communication
- Remote command execution
- Port forwarding capabilities
- Port 22

**Use Cases**:
- Remote server administration
- Secure file transfer (SCP, SFTP)
- Tunneling and port forwarding
- Git operations

### WebRTC (Web Real-Time Communication)
**Characteristics**:
- Peer-to-peer communication
- Real-time audio/video
- Browser-to-browser connectivity
- No plugins required

**Components**:
- **ICE**: Interactive Connectivity Establishment
- **STUN**: Session Traversal Utilities for NAT
- **TURN**: Traversal Using Relays around NAT

## Protocol Comparison

### Reliability vs Speed
| Protocol | Reliability | Speed | Use Case |
|----------|-------------|-------|----------|
| TCP | High | Medium | Web, email |
| UDP | Low | High | Streaming, gaming |
| HTTP | High | Medium | Web browsing |
| WebSocket | High | High | Real-time apps |

### Connection Model
| Protocol | Connection | State | Overhead |
|----------|------------|-------|----------|
| TCP | Persistent | Stateful | High |
| UDP | Connectionless | Stateless | Low |
| HTTP | Stateless | Stateless | Medium |
| WebSocket | Persistent | Stateful | Medium |

## Protocol Selection Guide

### Choose TCP When:
- Reliability is critical
- Order matters
- Connection setup overhead is acceptable
- Flow control is needed

### Choose UDP When:
- Speed is more important than reliability
- Real-time requirements
- Can handle packet loss
- Low overhead is critical

### Choose HTTP When:
- Standard web communication
- Firewall-friendly
- Stateless operations required
- Wide client support needed

### Choose WebSockets When:
- Real-time bidirectional communication
- Low latency required
- Long-lived connections
- Server push capability needed

## Security Considerations

### Transport Layer Security (TLS)
- Encrypts communication
- Certificate-based authentication
- Perfect forward secrecy
- Supported by most modern protocols

### Protocol-specific Security
- **HTTPS**: HTTP over TLS
- **SSH**: Built-in encryption
- **SMTPS**: SMTP over TLS
- **WSS**: Secure WebSockets

## Performance Optimization

### Connection Management
- **Connection pooling**: Reuse connections
- **Keep-alive**: Persistent connections
- **HTTP/2**: Multiplexing over single connection
- **QUIC**: UDP-based transport for HTTP/3

### Data Transfer
- **Compression**: Reduce data size
- **Binary protocols**: More efficient than text
- **Batching**: Group multiple operations
- **Caching**: Store frequently accessed data

## Implementation Examples

### TCP Server Example
```python
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('localhost', 8080))
server.listen(5)

while True:
    client, addr = server.accept()
    data = client.recv(1024)
    client.send(b"Hello, World!")
    client.close()
```

### WebSocket Client Example
```javascript
const ws = new WebSocket('ws://localhost:8080');

ws.onopen = function(event) {
    console.log('Connected to WebSocket server');
    ws.send('Hello Server');
};

ws.onmessage = function(event) {
    console.log('Received:', event.data);
};

ws.onclose = function(event) {
    console.log('WebSocket connection closed');
};
```

---

**Key Takeaway**: Protocol selection is a critical design decision that impacts reliability, performance, and complexity. Understanding the trade-offs enables informed architectural choices.
