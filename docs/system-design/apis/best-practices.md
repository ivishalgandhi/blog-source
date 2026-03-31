---
title: API Best Practices
description: Security, versioning, optimization, and design patterns
sidebar_position: 44
---

# API Best Practices

This section covers essential best practices for designing, implementing, and maintaining robust and scalable APIs.

## Security Practices

### Authentication

#### API Keys
- **Simple implementation**: Easy to implement and manage
- **Rate limiting**: Track usage per key
- **Revocation**: Disable compromised keys
- **Scope limitation**: Restrict key permissions

**Implementation**:
```javascript
// Express.js API key middleware
const apiKeys = new Map([
  ['key123', { id: 1, scopes: ['read', 'write'] }],
  ['key456', { id: 2, scopes: ['read'] }]
]);

function apiKeyMiddleware(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  const keyInfo = apiKeys.get(apiKey);
  if (!keyInfo) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  
  req.apiKey = keyInfo;
  next();
}
```

#### OAuth 2.0
- **Industry standard**: Widely adopted
- **Token-based**: JWT or opaque tokens
- **Scopes and permissions**: Granular access control
- **Refresh tokens**: Long-lived access

#### JWT (JSON Web Tokens)
- **Stateless**: No server-side session storage
- **Self-contained**: Contains user information
- **Signature verification**: Security guarantee
- **Expiration**: Built-in token lifetime

```javascript
const jwt = require('jsonwebtoken');

function generateToken(user) {
  return jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
}

function verifyToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Token required' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

### Authorization

#### Role-Based Access Control (RBAC)
- **User roles**: Admin, user, guest
- **Resource permissions**: Read, write, delete
- **Hierarchical roles**: Role inheritance
- **Dynamic permissions**: Context-based access

```javascript
function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
}

// Usage
app.post('/admin/users', verifyToken, requireRole('admin'), createUser);
```

#### Attribute-Based Access Control (ABAC)
- **Fine-grained control**: Attribute-based decisions
- **Context awareness**: Time, location, device
- **Dynamic policies**: Rule-based access
- **Complex scenarios**: Enterprise requirements

### Rate Limiting
- **Prevent abuse**: Protect against DDoS
- **Fair usage**: Ensure equal access
- **Tiered limits**: Different limits per user tier
- **Sliding windows**: Time-based rate limiting

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});

app.use('/api/', limiter);
```

### Input Validation
- **Sanitize inputs**: Prevent injection attacks
- **Validate types**: Ensure correct data types
- **Length limits**: Prevent buffer overflows
- **Whitelist approach**: Allow only known good inputs

```javascript
const { body, validationResult } = require('express-validator');

const userValidation = [
  body('email').isEmail().normalizeEmail(),
  body('name').isLength({ min: 2, max: 50 }).trim(),
  body('age').isInt({ min: 18, max: 120 })
];

function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

app.post('/users', userValidation, handleValidationErrors, createUser);
```

## API Versioning

### URL Path Versioning
```javascript
// Version 1
app.get('/v1/users', getUsersV1);

// Version 2
app.get('/v2/users', getUsersV2);
```

### Header Versioning
```javascript
app.get('/users', (req, res) => {
  const version = req.headers['api-version'] || 'v1';
  
  switch (version) {
    case 'v1':
      return getUsersV1(req, res);
    case 'v2':
      return getUsersV2(req, res);
    default:
      return res.status(400).json({ error: 'Unsupported version' });
  }
});
```

### Query Parameter Versioning
```javascript
app.get('/users', (req, res) => {
  const version = req.query.version || 'v1';
  
  if (version === 'v1') {
    return getUsersV1(req, res);
  } else if (version === 'v2') {
    return getUsersV2(req, res);
  }
  
  res.status(400).json({ error: 'Unsupported version' });
});
```

## Performance Optimization

### Caching Strategies

#### Response Caching
```javascript
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 600 }); // 10 minutes

function cacheMiddleware(duration = 600) {
  return (req, res, next) => {
    const key = req.originalUrl;
    const cached = cache.get(key);
    
    if (cached) {
      return res.json(cached);
    }
    
    const originalSend = res.json;
    res.json = function(data) {
      cache.set(key, data, duration);
      originalSend.call(this, data);
    };
    
    next();
  };
}

app.get('/users', cacheMiddleware(300), getUsers);
```

#### Database Query Caching
```javascript
const queryCache = new Map();

async function getCachedUser(id) {
  const cacheKey = `user:${id}`;
  
  if (queryCache.has(cacheKey)) {
    return queryCache.get(cacheKey);
  }
  
  const user = await User.findById(id);
  queryCache.set(cacheKey, user);
  
  // Remove from cache after 5 minutes
  setTimeout(() => {
    queryCache.delete(cacheKey);
  }, 5 * 60 * 1000);
  
  return user;
}
```

### Connection Pooling
```javascript
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'password',
  database: 'myapp',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function getUsers() {
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.execute('SELECT * FROM users');
    return rows;
  } finally {
    connection.release();
  }
}
```

### Compression
```javascript
const compression = require('compression');

app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  level: 6,
  threshold: 1024
}));
```

## Documentation

### OpenAPI/Swagger
```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
  description: API for managing users

paths:
  /users:
    get:
      summary: Get all users
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
    post:
      summary: Create a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created successfully

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
        createdAt:
          type: string
          format: date-time
```

### API Documentation Tools
- **Swagger UI**: Interactive API documentation
- **Redoc**: Clean API documentation
- **Postman**: API testing and documentation
- **API Blueprint**: Markdown-based documentation

## Error Handling

### Consistent Error Format
```javascript
class ApiError extends Error {
  constructor(statusCode, message, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
  }
}

function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details
      }
    });
  }
  
  // Log unexpected errors
  console.error('Unexpected error:', err);
  
  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred'
    }
  });
}

// Usage
try {
  const user = await User.findById(id);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }
  res.json({ data: user });
} catch (error) {
  next(error);
}
```

### HTTP Status Codes
- **200 OK**: Successful request
- **201 Created**: Resource created
- **400 Bad Request**: Invalid input
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

## Monitoring and Analytics

### API Metrics
- **Request count**: Total requests per endpoint
- **Response time**: Average and percentile response times
- **Error rate**: Percentage of failed requests
- **Active users**: Number of unique API consumers

```javascript
const prometheus = require('prom-client');

// Create metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

const httpRequestTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

// Middleware to record metrics
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      status: res.statusCode
    };
    
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });
  
  next();
}

app.use(metricsMiddleware);
```

### Logging
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

function requestLogger(req, res, next) {
  logger.info({
    method: req.method,
    url: req.url,
    userAgent: req.get('User-Agent'),
    ip: req.ip,
    timestamp: new Date().toISOString()
  });
  next();
}

app.use(requestLogger);
```

## Testing

### Unit Testing
```javascript
const request = require('supertest');
const app = require('../app');

describe('Users API', () => {
  test('GET /users should return users list', async () => {
    const response = await request(app)
      .get('/api/users')
      .expect(200);
    
    expect(response.body).toHaveProperty('data');
    expect(Array.isArray(response.body.data)).toBe(true);
  });
  
  test('POST /users should create new user', async () => {
    const userData = {
      name: 'John Doe',
      email: 'john@example.com'
    };
    
    const response = await request(app)
      .post('/api/users')
      .send(userData)
      .expect(201);
    
    expect(response.body.data).toMatchObject(userData);
  });
});
```

### Integration Testing
```javascript
describe('Users Integration Tests', () => {
  test('Complete user lifecycle', async () => {
    // Create user
    const createResponse = await request(app)
      .post('/api/users')
      .send({ name: 'Jane Doe', email: 'jane@example.com' })
      .expect(201);
    
    const userId = createResponse.body.data.id;
    
    // Get user
    const getResponse = await request(app)
      .get(`/api/users/${userId}`)
      .expect(200);
    
    expect(getResponse.body.data.name).toBe('Jane Doe');
    
    // Update user
    await request(app)
      .put(`/api/users/${userId}`)
      .send({ name: 'Jane Smith' })
      .expect(200);
    
    // Delete user
    await request(app)
      .delete(`/api/users/${userId}`)
      .expect(204);
  });
});
```

## Best Practices Summary

### Security
- [ ] Implement proper authentication and authorization
- [ ] Use HTTPS for all API communications
- [ ] Validate and sanitize all inputs
- [ ] Implement rate limiting
- [ ] Log security events

### Performance
- [ ] Implement caching strategies
- [ ] Use connection pooling
- [ ] Enable compression
- [ ] Monitor performance metrics
- [ ] Optimize database queries

### Reliability
- [ ] Implement proper error handling
- [ ] Use appropriate HTTP status codes
- [ ] Add comprehensive logging
- [ ] Implement health checks
- [ ] Design for scalability

### Documentation
- [ ] Provide clear API documentation
- [ ] Include examples and use cases
- [ ] Document error responses
- [ ] Keep documentation up to date
- [ ] Provide interactive documentation

---

**Key Takeaway**: Building robust APIs requires attention to security, performance, reliability, and documentation throughout the development lifecycle.
