# Drishti AI - Backend Server

Node.js + Express backend for Drishti AI vision assistant.

## Setup

1. **Install dependencies**
```bash
npm install
```

2. **Configure environment**
```bash
# Copy .env.example from root directory
cp ../.env.example .env

# Edit .env with your values
```

3. **Start MongoDB**
Ensure MongoDB is running locally or configure MONGO_URI for cloud instance.

4. **Start Ollama**
```bash
ollama serve
# Make sure gemma:4b model is installed
ollama pull gemma:4b
```

5. **Run server**
```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

Server will start on `http://localhost:5000`

## API Documentation

### Health Check
```
GET /api/health
```

### Authentication Routes (`/api/auth`)
- `POST /signup` - Register user
- `POST /login` - Login user
- `POST /verify-email` - Verify email
- `POST /forgot-password` - Request reset
- `POST /reset-password` - Reset password

### Model Routes (`/api/model`)
- `POST /analyze` - Analyze image with AI
- `POST /identify` - Identify person (placeholder)
- `GET /health` - Check Ollama status

### Alert Routes (`/api/alerts`)
- `GET /` - Get alerts (with filters)
- `GET /:id` - Get single alert
- `POST /` - Create alert
- `POST /:id/acknowledge` - Acknowledge alert
- `GET /stats/summary` - Get statistics

### User Routes (`/api/users`)
- `GET /me` - Get profile
- `PUT /me` - Update profile
- `POST /connect` - Connect with user
- `GET /connected` - Get connections

### Known Persons (`/api/known-persons`)
- `GET /` - Get known persons
- `POST /` - Add known person (with images)
- `PUT /:id` - Update known person
- `DELETE /:id` - Delete known person

### Subscriptions (`/api/subscribe`)
- `POST /` - Subscribe to alerts
- `GET /` - Get subscriptions
- `PUT /:id` - Update subscription
- `DELETE /:id` - Unsubscribe

### Admin Routes (`/api/admin`)
- `GET /users` - Get all users
- `GET /alerts` - Get all alerts
- `GET /stats` - System statistics
- `PUT /users/:id/role` - Update role
- `GET /audit-logs` - View audit logs

## Security

- Rate limiting on all routes
- JWT authentication required for protected routes
- Role-based access control
- Input validation
- Password hashing with bcrypt
- Helmet.js security headers

## Database Models

- **User** - User accounts with roles
- **Alert** - Detected hazards and warnings
- **KnownPerson** - Labeled person images
- **Subscription** - Alert subscriptions
- **AuditLog** - System activity logs

## Testing

Check Ollama integration:
```bash
curl http://localhost:11434/api/tags
```

Test health endpoint:
```bash
curl http://localhost:5000/api/health
```
