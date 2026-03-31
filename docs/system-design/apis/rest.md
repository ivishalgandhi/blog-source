---
title: REST APIs
description: RESTful principles, HTTP methods, and API design patterns
sidebar_position: 41
---

# REST APIs

REST (Representational State Transfer) is an architectural style for designing networked applications using HTTP protocols.

## REST Principles

### Architectural Constraints

#### Client-Server Architecture
- **Separation of concerns**: Client handles UI, server handles data
- **Independence**: Client and server can evolve independently
- **Scalability**: Server can scale without affecting clients
- **Portability**: Clients can be deployed on different platforms

#### Statelessness
> "HTTP is a request-response protocol but imagine it as a conversation with no memory."

- **No session state**: Each request contains all necessary information
- **Server simplicity**: No need to maintain client state
- **Reliability**: Easier to recover from failures
- **Scalability**: Load balancers can distribute requests freely

#### Cacheability
- **Explicit caching**: Responses must define cacheability
- **Performance**: Reduce client-server interactions
- **Scalability**: Reduce server load
- **Efficiency**: Better network utilization

#### Uniform Interface
- **Standardization**: Consistent interface across all resources
- **Simplicity**: Easier to understand and use
- **Evolution**: Independent evolution of components
- **Interoperability**: Different clients can work with same API

#### Layered System
- **Hierarchical architecture**: Multiple layers between client and server
- **Encapsulation**: Each layer sees only adjacent layers
- **Load balancing**: Multiple servers behind single interface
- **Security**: Additional security layers

#### Code on Demand (Optional)
- **Server logic**: Server can send executable code to client
- **Flexibility**: Extend client functionality dynamically
- **Complexity**: Adds implementation complexity
- **Security**: Potential security risks

## HTTP Methods and Status Codes

### HTTP Methods

#### GET
- **Purpose**: Retrieve resource representation
- **Idempotent**: Multiple calls have same effect
- **Safe**: Does not modify server state
- **Cacheable**: Responses can be cached

#### POST
- **Purpose**: Create new resource
- **Non-idempotent**: Multiple calls create multiple resources
- **Not safe**: Modifies server state
- **Not cacheable**: Typically not cached

#### PUT
- **Purpose**: Update or replace resource
- **Idempotent**: Multiple calls have same effect
- **Not safe**: Modifies server state
- **Not cacheable**: Typically not cached

#### PATCH
- **Purpose**: Partial update of resource
- **Non-idempotent**: Depends on implementation
- **Not safe**: Modifies server state
- **Not cacheable**: Typically not cached

#### DELETE
- **Purpose**: Delete resource
- **Idempotent**: Multiple calls have same effect
- **Not safe**: Modifies server state
- **Not cacheable**: Typically not cached

### HTTP Status Codes

#### 2xx Success Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **202 Accepted**: Request accepted for processing
- **204 No Content**: Request successful, no content returned

#### 3xx Redirection Codes
- **301 Moved Permanently**: Resource permanently moved
- **302 Found**: Resource temporarily moved
- **304 Not Modified**: Resource not modified (conditional GET)

#### 4xx Client Error Codes
- **400 Bad Request**: Invalid request syntax
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Access denied
- **404 Not Found**: Resource not found
- **409 Conflict**: Request conflicts with current state

#### 5xx Server Error Codes
- **500 Internal Server Error**: Unexpected server error
- **502 Bad Gateway**: Invalid response from upstream server
- **503 Service Unavailable**: Server temporarily unavailable
- **504 Gateway Timeout**: Upstream server timeout

## Resource Design

### Resource Identification
- **URI design**: Use nouns, not verbs
- **Hierarchical structure**: Reflect resource relationships
- **Plural nouns**: Use plural form for collections
- **Consistent naming**: Follow naming conventions

**Good Examples**:
```
GET /users          # Get all users
GET /users/123      # Get specific user
GET /users/123/orders  # Get user's orders
POST /users         # Create new user
PUT /users/123      # Update user
DELETE /users/123   # Delete user
```

**Bad Examples**:
```
GET /getAllUsers
POST /createUser
GET /users?id=123&action=delete
```

### Resource Representations
- **JSON format**: Standard for modern APIs
- **Consistent structure**: Uniform response format
- **Links and relationships**: HATEOAS principles
- **Metadata**: Pagination, timestamps, version info

**Response Structure Example**:
```json
{
  "data": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z"
  },
  "links": {
    "self": "/users/123",
    "orders": "/users/123/orders"
  },
  "meta": {
    "version": "v1",
    "timestamp": "2023-01-01T00:00:00Z"
  }
}
```

## API Design Patterns

### Pagination
- **Limit/Offset**: Simple but inefficient for large datasets
- **Cursor-based**: More efficient for large datasets
- **Page-based**: Fixed-size pages
- **Infinite scroll**: Cursor-based with automatic loading

**Limit/Offset Example**:
```
GET /users?limit=20&offset=40
```

**Cursor-based Example**:
```
GET /users?limit=20&after=cursor123
```

### Filtering and Sorting
- **Query parameters**: Filter resources
- **Multiple filters**: Combine multiple criteria
- **Sorting**: Order results by specific fields
- **Default sorting**: Predictable default order

**Filtering Example**:
```
GET /users?status=active&role=admin
```

**Sorting Example**:
```
GET /users?sort=created_at:desc,name:asc
```

### Versioning
- **URL versioning**: /v1/users, /v2/users
- **Header versioning**: Accept: application/vnd.api+json;version=1
- **Query parameter**: /users?version=1
- **Content negotiation**: Different media types

### Error Handling
- **Consistent format**: Standardized error responses
- **Detailed information**: Error codes, messages, details
- **HTTP status codes**: Appropriate status codes
- **Validation errors**: Field-specific error information

**Error Response Example**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "age",
        "message": "Age must be between 18 and 100"
      }
    ]
  }
}
```

## Implementation Examples

### Express.js REST API
```javascript
const express = require('express');
const app = express();

app.use(express.json());

// GET /users
app.get('/users', async (req, res) => {
  const { limit = 10, offset = 0 } = req.query;
  const users = await User.find().limit(limit).skip(offset);
  res.json({ data: users });
});

// GET /users/:id
app.get('/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    return res.status(404).json({ 
      error: { code: 'NOT_FOUND', message: 'User not found' }
    });
  }
  res.json({ data: user });
});

// POST /users
app.post('/users', async (req, res) => {
  try {
    const user = await User.create(req.body);
    res.status(201).json({ data: user });
  } catch (error) {
    res.status(400).json({ 
      error: { code: 'VALIDATION_ERROR', message: error.message }
    });
  }
});

// PUT /users/:id
app.put('/users/:id', async (req, res) => {
  const user = await User.findByIdAndUpdate(
    req.params.id, 
    req.body, 
    { new: true, runValidators: true }
  );
  if (!user) {
    return res.status(404).json({ 
      error: { code: 'NOT_FOUND', message: 'User not found' }
    });
  }
  res.json({ data: user });
});

// DELETE /users/:id
app.delete('/users/:id', async (req, res) => {
  const user = await User.findByIdAndDelete(req.params.id);
  if (!user) {
    return res.status(404).json({ 
      error: { code: 'NOT_FOUND', message: 'User not found' }
    });
  }
  res.status(204).send();
});

app.listen(3000, () => console.log('Server running on port 3000'));
```

### Spring Boot REST API
```java
@RestController
@RequestMapping("/users")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    public ResponseEntity<ApiResponse<List<User>>> getUsers(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        List<User> users = userService.getUsers(limit, offset);
        return ResponseEntity.ok(ApiResponse.success(users));
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<User>> getUser(@PathVariable Long id) {
        return userService.getUser(id)
            .map(user -> ResponseEntity.ok(ApiResponse.success(user)))
            .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<ApiResponse<User>> createUser(@Valid @RequestBody CreateUserRequest request) {
        User user = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(user));
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<User>> updateUser(
            @PathVariable Long id, 
            @Valid @RequestBody UpdateUserRequest request) {
        return userService.updateUser(id, request)
            .map(user -> ResponseEntity.ok(ApiResponse.success(user)))
            .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        if (userService.deleteUser(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
```

## Best Practices

### Design Principles
- **Consistency**: Uniform interface and naming conventions
- **Simplicity**: Easy to understand and use
- **Flexibility**: Support for different client needs
- **Performance**: Efficient resource utilization

### Security Considerations
- **Authentication**: Verify client identity
- **Authorization**: Control access to resources
- **HTTPS**: Encrypt communication
- **Input validation**: Prevent injection attacks

### Performance Optimization
- **Caching**: Implement appropriate caching strategies
- **Compression**: Reduce response size
- **Connection pooling**: Reuse connections
- **Pagination**: Limit response sizes

---

**Key Takeaway**: REST APIs provide a simple, scalable, and widely adopted approach to building web services that leverage HTTP's strengths while maintaining statelessness and cacheability.
