---
title: gRPC
description: High-performance RPC framework with Protocol Buffers
sidebar_position: 43
---

# gRPC APIs

gRPC is a high-performance, open-source RPC framework that uses Protocol Buffers for serialization and HTTP/2 for transport.

## gRPC Fundamentals

### Core Components

#### Protocol Buffers
- **Schema definition**: .proto files define services and messages
- **Code generation**: Auto-generate client and server code
- **Binary serialization**: Efficient data encoding
- **Language agnostic**: Support for multiple programming languages

#### HTTP/2 Transport
- **Multiplexing**: Multiple streams over single connection
- **Binary framing**: Efficient data transfer
- **Header compression**: Reduced overhead
- **Server push**: Proactive response sending

#### Service Definition
- **RPC methods**: Define remote procedure calls
- **Message types**: Strongly typed data structures
- **Streaming support**: Client, server, and bidirectional streaming
- **Package organization**: Namespace management

### gRPC vs REST

| Feature | gRPC | REST |
|---------|------|------|
| Protocol | HTTP/2 | HTTP/1.1, HTTP/2 |
| Serialization | Protocol Buffers | JSON, XML |
| Code Generation | Automatic | Manual |
| Streaming | Built-in | Limited |
| Performance | High | Medium |
| Browser Support | Limited | Native |
| Tooling | Generated | Manual |

## Protocol Buffers

### Message Definition
```protobuf
syntax = "proto3";

package user;

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  UserStatus status = 4;
  repeated Order orders = 5;
  google.protobuf.Timestamp created_at = 6;
  google.protobuf.Timestamp updated_at = 7;
}

message Order {
  string id = 1;
  string user_id = 2;
  double total = 3;
  string status = 4;
  repeated OrderItem items = 5;
  google.protobuf.Timestamp created_at = 6;
}

message OrderItem {
  string product_id = 1;
  string name = 2;
  double price = 3;
  int32 quantity = 4;
}

enum UserStatus {
  USER_STATUS_UNSPECIFIED = 0;
  USER_STATUS_ACTIVE = 1;
  USER_STATUS_INACTIVE = 2;
  USER_STATUS_SUSPENDED = 3;
}
```

### Service Definition
```protobuf
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
  
  // Streaming methods
  rpc StreamUsers(StreamUsersRequest) returns (stream UserResponse);
  rpc CreateUserStream(stream CreateUserRequest) returns (CreateUserResponse);
  rpc BidirectionalStream(stream BidirectionalRequest) returns (stream BidirectionalResponse);
}

message GetUserRequest {
  string user_id = 1;
}

message GetUserResponse {
  User user = 1;
}

message ListUsersRequest {
  int32 limit = 1;
  int32 offset = 2;
  UserStatus status = 3;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total_count = 2;
}
```

## gRPC Patterns

### Unary RPC
**Request-Response**: Single request, single response

```protobuf
rpc GetUser(GetUserRequest) returns (GetUserResponse);
```

### Server Streaming
**Single Request, Multiple Responses**: Client sends one request, server streams back responses

```protobuf
rpc StreamUsers(StreamUsersRequest) returns (stream UserResponse);
```

### Client Streaming
**Multiple Requests, Single Response**: Client streams requests, server responds once

```protobuf
rpc CreateUserStream(stream CreateUserRequest) returns (CreateUserResponse);
```

### Bidirectional Streaming
**Multiple Requests, Multiple Responses**: Both client and server stream independently

```protobuf
rpc BidirectionalStream(stream BidirectionalRequest) returns (stream BidirectionalResponse);
```

## Implementation Examples

### gRPC Server (Node.js)
```javascript
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const PROTO_PATH = './user.proto';
const packageDefinition = protoLoader.loadSync(PROTO_PATH);
const userProto = grpc.loadPackageDefinition(packageDefinition).user;

class UserServiceImpl {
  async getUser(call, callback) {
    try {
      const { user_id } = call.request;
      const user = await User.findById(user_id);
      
      if (!user) {
        callback({
          code: grpc.status.NOT_FOUND,
          details: 'User not found'
        });
        return;
      }
      
      callback(null, { user });
    } catch (error) {
      callback({
        code: grpc.status.INTERNAL,
        details: error.message
      });
    }
  }
  
  async listUsers(call, callback) {
    try {
      const { limit = 10, offset = 0, status } = call.request;
      const users = await User.find(status ? { status } : {})
        .limit(limit)
        .skip(offset);
      
      const totalCount = await User.countDocuments(status ? { status } : {});
      
      callback(null, { users, total_count: totalCount });
    } catch (error) {
      callback({
        code: grpc.status.INTERNAL,
        details: error.message
      });
    }
  }
  
  async createUser(call, callback) {
    try {
      const { name, email, status = 'USER_STATUS_ACTIVE' } = call.request;
      const user = await User.create({
        name,
        email,
        status,
        created_at: new Date(),
        updated_at: new Date()
      });
      
      callback(null, { user });
    } catch (error) {
      callback({
        code: grpc.status.INVALID_ARGUMENT,
        details: error.message
      });
    }
  }
  
  async streamUsers(call) {
    try {
      const { limit = 10, status } = call.request;
      const users = await User.find(status ? { status } : {}).limit(limit);
      
      for (const user of users) {
        call.write({ user });
      }
      
      call.end();
    } catch (error) {
      call.destroy({
        code: grpc.status.INTERNAL,
        details: error.message
      });
    }
  }
}

const server = new grpc.Server();
server.addService(userProto.UserService.service, new UserServiceImpl());

server.bindAsync('0.0.0.0:50051', grpc.ServerCredentials.createInsecure())
  .then(() => {
    server.start();
    console.log('gRPC server running on port 50051');
  })
  .catch(error => {
    console.error('Failed to start server:', error);
  });
```

### gRPC Client (Node.js)
```javascript
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const PROTO_PATH = './user.proto';
const packageDefinition = protoLoader.loadSync(PROTO_PATH);
const userProto = grpc.loadPackageDefinition(packageDefinition).user;

const client = new userProto.UserService(
  'localhost:50051',
  grpc.credentials.createInsecure()
);

// Unary call
function getUser(userId) {
  return new Promise((resolve, reject) => {
    client.getUser({ user_id: userId }, (error, response) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(response.user);
    });
  });
}

// Server streaming
function streamUsers(limit = 10) {
  const call = client.streamUsers({ limit });
  
  call.on('data', (response) => {
    console.log('Received user:', response.user);
  });
  
  call.on('end', () => {
    console.log('Stream ended');
  });
  
  call.on('error', (error) => {
    console.error('Stream error:', error);
  });
}

// Usage examples
async function main() {
  try {
    // Get single user
    const user = await getUser('123');
    console.log('User:', user);
    
    // Stream users
    streamUsers(5);
  } catch (error) {
    console.error('Error:', error);
  }
}

main();
```

### gRPC Server (Go)
```go
package main

import (
	"context"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "path/to/proto/user"
)

type server struct {
	pb.UnimplementedUserServiceServer
}

func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
	userID := req.GetUserId()
	
	// Simulate database lookup
	user := &pb.User{
		Id:        userID,
		Name:      "John Doe",
		Email:     "john@example.com",
		Status:    pb.UserStatus_USER_STATUS_ACTIVE,
		CreatedAt: timestamppb.Now(),
		UpdatedAt: timestamppb.Now(),
	}
	
	return &pb.GetUserResponse{User: user}, nil
}

func (s *server) ListUsers(ctx context.Context, req *pb.ListUsersRequest) (*pb.ListUsersResponse, error) {
	limit := req.GetLimit()
	if limit == 0 {
		limit = 10
	}
	
	// Simulate database lookup
	users := make([]*pb.User, 0, limit)
	for i := 0; i < int(limit); i++ {
		users = append(users, &pb.User{
			Id:        fmt.Sprintf("user_%d", i),
			Name:      fmt.Sprintf("User %d", i),
			Email:     fmt.Sprintf("user%d@example.com", i),
			Status:    pb.UserStatus_USER_STATUS_ACTIVE,
			CreatedAt: timestamppb.Now(),
			UpdatedAt: timestamppb.Now(),
		})
	}
	
	return &pb.ListUsersResponse{
		Users:     users,
		TotalCount: int32(len(users)),
	}, nil
}

func (s *server) StreamUsers(req *pb.StreamUsersRequest, stream pb.UserService_StreamUsersServer) error {
	limit := req.GetLimit()
	if limit == 0 {
		limit = 10
	}
	
	for i := 0; i < int(limit); i++ {
		user := &pb.User{
			Id:        fmt.Sprintf("user_%d", i),
			Name:      fmt.Sprintf("User %d", i),
			Email:     fmt.Sprintf("user%d@example.com", i),
			Status:    pb.UserStatus_USER_STATUS_ACTIVE,
			CreatedAt: timestamppb.Now(),
			UpdatedAt: timestamppb.Now(),
		}
		
		if err := stream.Send(&pb.UserResponse{User: user}); err != nil {
			return err
		}
		
		time.Sleep(100 * time.Millisecond) // Simulate work
	}
	
	return nil
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}
	
	s := grpc.NewServer()
	pb.RegisterUserServiceServer(s, &server{})
	
	log.Println("gRPC server listening on :50051")
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
```

## Advanced Features

### Interceptors
```javascript
// Logging interceptor
const loggingInterceptor = (options, nextCall) => {
  return new InterceptingCall(nextCall(options), {
    start: function(metadata, listener, next) {
      console.log('Starting call:', metadata);
      next(metadata, {
        onReceiveMessage: function(message, next) {
          console.log('Received message:', message);
          next(message);
        },
        onReceiveStatus: function(status, next) {
          console.log('Call completed with status:', status);
          next(status);
        }
      });
    }
  });
};

// Authentication interceptor
const authInterceptor = (options, nextCall) => {
  const metadata = options.metadata || new Map();
  const token = metadata.get('authorization');
  
  if (!token || !isValidToken(token)) {
    throw new Error('Unauthorized');
  }
  
  return nextCall(options);
};
```

### Load Balancing
```javascript
// Round-robin load balancing
const addresses = [
  'localhost:50051',
  'localhost:50052',
  'localhost:50053'
];

const client = new userProto.UserService(
  addresses,
  grpc.credentials.createInsecure(),
  {
    'grpc.load_balancing_policy': 'round_robin'
  }
);
```

### Deadlines and Timeouts
```javascript
// Set deadline for call
const deadline = new Date(Date.now() + 5000); // 5 seconds
client.getUser({ user_id: '123' }, { deadline }, (error, response) => {
  if (error) {
    if (error.code === grpc.status.DEADLINE_EXCEEDED) {
      console.log('Call timed out');
    }
    return;
  }
  console.log('User:', response.user);
});
```

## Best Practices

### Service Design
- **Idempotent methods**: Design for retry safety
- **Error handling**: Use appropriate gRPC status codes
- **Streaming**: Use streaming for large datasets
- **Versioning**: Plan for API evolution

### Performance Optimization
- **Connection pooling**: Reuse connections
- **Compression**: Enable response compression
- **Deadlines**: Set appropriate timeouts
- **Batching**: Group related operations

### Security
- **TLS**: Use encrypted connections
- **Authentication**: Implement proper auth
- **Authorization**: Control access to methods
- **Metadata**: Use metadata for auth tokens

---

**Key Takeaway**: gRPC provides high-performance, type-safe RPC communication with built-in streaming support, making it ideal for microservices and internal APIs where performance and type safety are critical.
