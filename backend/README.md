# CollabChat Backend - Complete Setup & API Guide

A real-time chat and collaboration platform backend built with **Express.js**, **Node.js**, and **MongoDB Atlas**.

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Project Structure](#project-structure)
5. [API Reference](#api-reference)
6. [WebSocket Events](#websocket-events)
7. [Deployment](#deployment)

---

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd collabchat-backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret

# Run development server
npm run dev

# Run production server
npm start
```

Server will be running at `http://localhost:3001`

---

## 📦 Installation

### Prerequisites

- Node.js 16+
- npm or yarn
- MongoDB Atlas account (free tier available)
- Git

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Environment Configuration

Create a `.env` file in the root directory:

```env
# Server
PORT=3001
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/collabchat?retryWrites=true&w=majority

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=7d

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
```

### Step 3: Verify MongoDB Connection

```bash
node test-db.js
```

Expected output:
```
✓ Connected to MongoDB
```

---

## 🗄️ MongoDB Atlas Setup

### Create MongoDB Atlas Account

1. Go to [mongodb.com/cloud/atlas](https://mongodb.com/cloud/atlas)
2. Sign up for free
3. Create a cluster (M0 free tier)
4. Create a database user with read/write permissions
5. Get your connection string and add to `.env`

### IP Whitelist

For development, allow `0.0.0.0/0` (all IPs). For production, use specific IPs.

---

## 📁 Project Structure

```
collabchat-backend/
├── models/                 # Database schemas
│   ├── User.js
│   ├── Chat.js
│   ├── Message.js
│   └── Group.js
├── routes/                 # API route handlers
│   ├── auth.js
│   ├── users.js
│   ├── groups.js
│   └── chats.js
├── controllers/            # Business logic
│   ├── authController.js
│   ├── usersController.js
│   ├── groupsController.js
│   └── chatsController.js
├── middleware/             # Express middleware
│   └── auth.js
├── socket-io-setup.js      # WebSocket configuration
├── server.js               # Main server file
├── .env                    # Environment variables
├── .gitignore
├── package.json
├── Dockerfile
└── README.md
```

---

## 🔌 API Reference

### Base URL

```
http://localhost:3001/api/v1
```

### Authentication Endpoints

#### Register User

```http
POST /auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "password": "password123"
}
```

**Response (201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "username": "john_doe",
    "isOnline": false,
    "createdAt": "2026-02-07T10:00:00Z"
  }
}
```

---

#### Login User

```http
POST /auth/login
Content-Type: application/json

{
  "username": "john_doe",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "username": "john_doe",
    "isOnline": true,
    "lastSeen": "2026-02-07T10:05:00Z"
  }
}
```

---

### User Endpoints

#### Get Current User

```http
GET /users/me
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "username": "john_doe",
  "isOnline": true,
  "lastSeen": "2026-02-07T10:05:00Z",
  "createdAt": "2026-02-07T10:00:00Z"
}
```

---

#### Get All Users

```http
GET /users?limit=50&offset=0
Authorization: Bearer {token}
```

**Response (200):**
```json
[
  {
    "_id": "507f1f77bcf86cd799439011",
    "username": "alice",
    "isOnline": true,
    "lastSeen": "2026-02-07T10:05:00Z"
  },
  {
    "_id": "507f1f77bcf86cd799439012",
    "username": "bob",
    "isOnline": false,
    "lastSeen": "2026-02-07T09:30:00Z"
  }
]
```

---

### Group Endpoints

#### Create Group

```http
POST /groups
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Frontend Team",
  "members": ["507f1f77bcf86cd799439012", "507f1f77bcf86cd799439013"]
}
```

**Response (201):**
```json
{
  "_id": "507f1f77bcf86cd799439020",
  "name": "Frontend Team",
  "members": ["507f1f77bcf86cd799439011", "507f1f77bcf86cd799439012"],
  "adminId": "507f1f77bcf86cd799439011",
  "createdAt": "2026-02-07T10:00:00Z"
}
```

---

#### Get My Groups

```http
GET /groups/my
Authorization: Bearer {token}
```

**Response (200):**
```json
[
  {
    "_id": "507f1f77bcf86cd799439020",
    "name": "Frontend Team",
    "members": [...],
    "adminId": "507f1f77bcf86cd799439011",
    "createdAt": "2026-02-07T10:00:00Z"
  }
]
```

---

#### Add Group Member

```http
POST /groups/{groupId}/add
Authorization: Bearer {token}
Content-Type: application/json

{
  "userId": "507f1f77bcf86cd799439014"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User added to group"
}
```

---

### Chat Endpoints

#### Get Private Messages

```http
GET /chats/private/{userId}?limit=20&offset=0
Authorization: Bearer {token}
```

**Response (200):**
```json
[
  {
    "_id": "msg1",
    "senderId": "507f1f77bcf86cd799439011",
    "chatId": "chat1",
    "content": "Hello there!",
    "type": "text",
    "createdAt": "2026-02-07T10:00:00Z",
    "sender": {
      "_id": "507f1f77bcf86cd799439011",
      "username": "alice"
    }
  }
]
```

---

#### Get Group Messages

```http
GET /chats/group/{groupId}?limit=20&offset=0
Authorization: Bearer {token}
```

**Response (200):**
```json
[
  {
    "_id": "msg1",
    "senderId": "507f1f77bcf86cd799439011",
    "chatId": "507f1f77bcf86cd799439020",
    "content": "Hello team!",
    "type": "text",
    "createdAt": "2026-02-07T10:00:00Z",
    "sender": {
      "_id": "507f1f77bcf86cd799439011",
      "username": "alice"
    }
  }
]
```

---

## 🔌 WebSocket (Socket.IO) Events

### Client to Server Events

#### Join Chat

```javascript
socket.emit('join', { chatId: 'chat-id' });
```

---

#### Send Message

```javascript
socket.emit('send_message', {
  chatId: 'chat-id',
  message: 'Hello world!',
  type: 'text' // 'text' or 'file'
});
```

---

#### Typing Indicator

```javascript
// Start typing
socket.emit('typing', { chatId: 'chat-id' });

// Stop typing
socket.emit('stop_typing', { chatId: 'chat-id' });
```

---

### Server to Client Events

#### Receive Message

```javascript
socket.on('receive_message', (messageData) => {
  console.log(messageData);
  // messageData contains the new message
});
```

---

#### Typing Indicator

```javascript
socket.on('typing', (data) => {
  console.log(data.username + ' is typing...');
});

socket.on('stop_typing', (userId) => {
  console.log('User stopped typing');
});
```

---

#### Online Users

```javascript
socket.on('online_users', (userIds) => {
  console.log('Online users:', userIds);
});
```

---

## 🐳 Docker Deployment

### Build Docker Image

```bash
docker build -t collabchat-backend .
```

### Run with Docker

```bash
docker run -p 3001:3001 --env-file .env collabchat-backend
```

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - '3001:3001'
    environment:
      - PORT=3001
      - NODE_ENV=production
      - MONGODB_URI=${MONGODB_URI}
      - JWT_SECRET=${JWT_SECRET}
      - CORS_ORIGIN=${CORS_ORIGIN}
    restart: always
```

Run with Docker Compose:

```bash
docker-compose up -d
```

---

## 🚀 Deployment to Heroku

### Heroku Deployment

```bash
# Install Heroku CLI and login
heroku login

# Create app
heroku create collabchat-backend

# Set environment variables
heroku config:set MONGODB_URI="mongodb+srv://..." \
  JWT_SECRET="super-secret-key" \
  CORS_ORIGIN="https://your-frontend.herokuapp.com"

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

---

## 📚 Testing with curl

### Register User

```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'
```

### Login User

```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'
```

### Get Users

```bash
curl -X GET http://localhost:3001/api/v1/users \
  -H "Authorization: Bearer {token}"
```

---

## 📊 API Endpoints Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/v1/auth/register` | ✗ | Register new user |
| POST | `/api/v1/auth/login` | ✗ | Login user |
| GET | `/api/v1/users/me` | ✓ | Get current user |
| GET | `/api/v1/users` | ✓ | List all users |
| POST | `/api/v1/groups` | ✓ | Create group |
| GET | `/api/v1/groups/my` | ✓ | Get user's groups |
| POST | `/api/v1/groups/:id/add` | ✓ | Add member to group |
| GET | `/api/v1/chats/private/:userId` | ✓ | Get DM history |
| GET | `/api/v1/chats/group/:groupId` | ✓ | Get group history |
| GET | `/health` | ✗ | Health check |

---

## ✅ Setup Checklist

- [x] Project initialization
- [x] Dependencies installed
- [x] Database models created
- [x] Controllers implemented
- [x] Routes configured
- [x] Authentication middleware set up
- [x] Socket.IO configured
- [x] Environment variables configured
- [ ] MongoDB Atlas cluster created (manual)
- [ ] `.env` file updated with real credentials (manual)
- [ ] Dependencies installed: `npm install`
- [ ] Test connection: `node test-db.js`
- [ ] Start development server: `npm run dev`

---

## 🐛 Troubleshooting

### MongoDB Connection Error

Make sure your `.env` file has the correct `MONGODB_URI` and that your IP is whitelisted in MongoDB Atlas.

### Port Already in Use

Change the `PORT` in `.env` or kill the process using port 3001:

```bash
lsof -i :3001
kill -9 <PID>
```

### JWT Authentication Issues

Ensure `JWT_SECRET` in `.env` is set and matches between token generation and verification.

---

## 📝 License

MIT

---

**Built with ❤️ using Node.js & Express**
