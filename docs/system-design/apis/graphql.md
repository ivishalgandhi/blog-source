---
title: GraphQL
description: Query language, runtime, and API design patterns
sidebar_position: 42
---

# GraphQL APIs

GraphQL is a query language and runtime for APIs that enables clients to request exactly the data they need, avoiding over-fetching and under-fetching.

## GraphQL Fundamentals

### Core Concepts

#### Schema Definition
- **Type system**: Strongly typed schema
- **Operations**: Queries, mutations, subscriptions
- **Resolvers**: Functions that resolve fields
- **Introspection**: Self-documenting API

#### Single Endpoint
- **One URL**: All operations go to single endpoint
- **POST method**: Typically uses HTTP POST
- **HTTP headers**: Content-Type: application/json
- **Query structure**: JSON with query/mutation/subscription

#### Client-Driven Queries
> "GraphQL APIs allow clients to request exactly the data they need, avoiding over-fetching."

- **Specify fields**: Client chooses returned fields
- **Nested queries**: Request related data in single request
- **No versioning**: Schema evolution without breaking changes
- **Strong typing**: Compile-time validation

## GraphQL Operations

### Queries
**Purpose**: Fetch data from server

**Basic Query**:
```graphql
query GetUser {
  user(id: "123") {
    id
    name
    email
  }
}
```

**Nested Query**:
```graphql
query GetUserWithOrders {
  user(id: "123") {
    id
    name
    email
    orders {
      id
      total
      status
      items {
        name
        price
      }
    }
  }
}
```

**Query with Variables**:
```graphql
query GetUser($id: ID!, $includeOrders: Boolean!) {
  user(id: $id) {
    id
    name
    email
    orders @include(if: $includeOrders) {
      id
      total
    }
  }
}
```

**Variables**:
```json
{
  "id": "123",
  "includeOrders": true
}
```

### Mutations
**Purpose**: Modify data on server

**Create Mutation**:
```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    name
    email
    createdAt
  }
}
```

**Update Mutation**:
```graphql
mutation UpdateUser($id: ID!, $input: UpdateUserInput!) {
  updateUser(id: $id, input: $input) {
    id
    name
    email
    updatedAt
  }
}
```

**Delete Mutation**:
```graphql
mutation DeleteUser($id: ID!) {
  deleteUser(id: $id) {
    id
    success
    message
  }
}
```

### Subscriptions
**Purpose**: Real-time data updates

**Subscription**:
```graphql
subscription OnUserUpdated($userId: ID!) {
  userUpdated(userId: $userId) {
    id
    name
    email
    updatedAt
  }
}
```

## Schema Design

### Type System

#### Object Types
```graphql
type User {
  id: ID!
  name: String!
  email: String!
  status: UserStatus!
  orders: [Order!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

#### Enum Types
```graphql
enum UserStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
}
```

#### Input Types
```graphql
input CreateUserInput {
  name: String!
  email: String!
  status: UserStatus = ACTIVE
}
```

#### Union Types
```graphql
union SearchResult = User | Order | Product
```

#### Interface Types
```graphql
interface Node {
  id: ID!
  createdAt: DateTime!
}

type User implements Node {
  id: ID!
  name: String!
  email: String!
  createdAt: DateTime!
}
```

## Implementation Examples

### Apollo Server (Node.js)
```javascript
const { ApolloServer, gql } = require('apollo-server');

const typeDefs = gql`
  type User {
    id: ID!
    name: String!
    email: String!
    status: UserStatus!
    orders: [Order!]!
    createdAt: DateTime!
  }

  type Order {
    id: ID!
    total: Float!
    status: String!
    user: User!
    createdAt: DateTime!
  }

  enum UserStatus {
    ACTIVE
    INACTIVE
    SUSPENDED
  }

  input CreateUserInput {
    name: String!
    email: String!
    status: UserStatus = ACTIVE
  }

  type Query {
    user(id: ID!): User
    users(limit: Int = 10, offset: Int = 0): [User!]!
  }

  type Mutation {
    createUser(input: CreateUserInput!): User!
    updateUser(id: ID!, input: UpdateUserInput!): User!
    deleteUser(id: ID!): Boolean!
  }

  type Subscription {
    userUpdated(userId: ID!): User!
  }
`;

const resolvers = {
  Query: {
    user: async (_, { id }, { dataSources }) => {
      return await dataSources.userAPI.getUserById(id);
    },
    users: async (_, { limit, offset }, { dataSources }) => {
      return await dataSources.userAPI.getUsers(limit, offset);
    }
  },
  
  Mutation: {
    createUser: async (_, { input }, { dataSources }) => {
      return await dataSources.userAPI.createUser(input);
    }
  },
  
  User: {
    orders: async (user, _, { dataSources }) => {
      return await dataSources.orderAPI.getOrdersByUserId(user.id);
    }
  }
};

const server = new ApolloServer({
  typeDefs,
  resolvers,
  dataSources: () => ({
    userAPI: new UserAPI(),
    orderAPI: new OrderAPI()
  })
});

server.listen().then(({ url }) => {
  console.log(`Server ready at ${url}`);
});
```

### GraphQL Yoga (Node.js)
```javascript
import { createServer } from 'graphql-yoga';
import { schema } from './schema';

const server = createServer({
  schema,
  context: (request) => ({
    user: request.user,
    dataSources: {
      userAPI: new UserAPI(),
      orderAPI: new OrderAPI()
    }
  })
});

server.start(() => {
  console.log('Server is running on http://localhost:4000');
});
```

## Advanced Features

### Fragments
```graphql
fragment UserFields on User {
  id
  name
  email
}

query GetUsers {
  users {
    ...UserFields
  }
}
```

### Directives
```graphql
query GetUser($id: ID!, $includeEmail: Boolean!) {
  user(id: $id) {
    id
    name
    email @include(if: $includeEmail)
  }
}
```

### Custom Scalars
```javascript
const { GraphQLScalarType } = require('graphql');

const DateTime = new GraphQLScalarType({
  name: 'DateTime',
  description: 'DateTime custom scalar type',
  serialize(value) {
    return value.toISOString();
  },
  parseValue(value) {
    return new Date(value);
  },
  parseLiteral(ast) {
    return new Date(ast.value);
  }
});
```

## Performance Optimization

### Query Complexity Analysis
```javascript
const complexityLimit = 1000;

const complexityRule = {
  ComplexityLimit: {
    limit: complexityLimit,
    estimators: [
      simpleEstimator({ defaultComplexity: 1 }),
      fieldConfigEstimator()
    ]
  }
};

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [complexityRule.ComplexityLimit]
});
```

### Query Caching
```javascript
const { RedisCache } = require('apollo-server-cache-redis');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache: new RedisCache({
    host: 'redis-server',
    port: 6379
  }),
  plugins: [
    responseCachePlugin()
  ]
});
```

### DataLoader Implementation
```javascript
const DataLoader = require('dataloader');

const batchUsers = async (keys) => {
  const users = await User.find({ id: { $in: keys } });
  return keys.map(key => users.find(user => user.id === key));
};

const userLoader = new DataLoader(batchUsers, {
  maxBatchSize: 100,
  batchScheduleFn: () => new Promise(resolve => setTimeout(resolve, 10))
});
```

## Best Practices

### Schema Design
- **Granular types**: Break down large objects
- **Nullable vs non-null**: Use non-null for required fields
- **Consistent naming**: Follow naming conventions
- **Documentation**: Provide clear descriptions

### Resolver Design
- **DataLoader**: Prevent N+1 queries
- **Error handling**: Graceful error responses
- **Authentication**: Context-based auth
- **Authorization**: Field-level permissions

### Performance
- **Query complexity**: Limit complex queries
- **Caching**: Implement appropriate caching
- **Batching**: Use DataLoader for efficiency
- **Monitoring**: Track query performance

---

**Key Takeaway**: GraphQL provides flexible, efficient, and type-safe APIs that empower clients while maintaining server-side control and performance optimization capabilities.
