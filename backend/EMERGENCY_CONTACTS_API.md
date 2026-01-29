# Emergency Contacts & Connected Users API Documentation

## Emergency Contacts API

### Base URL: `/api/emergency-contacts`

### 1. Get All Emergency Contacts
**GET** `/api/emergency-contacts`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "contacts": [
    {
      "name": "John Doe",
      "phone": "+1234567890",
      "email": "john@example.com",
      "relationship": "Brother"
    }
  ],
  "count": 1
}
```

### 2. Add Emergency Contact
**POST** `/api/emergency-contacts`

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "name": "Jane Doe",
  "phone": "+1987654321",
  "email": "jane@example.com",
  "relationship": "Mother"
}
```

**Response:**
```json
{
  "message": "Emergency contact added successfully",
  "contact": {
    "name": "Jane Doe",
    "phone": "+1987654321",
    "email": "jane@example.com",
    "relationship": "Mother"
  }
}
```

### 3. Update Emergency Contact
**PUT** `/api/emergency-contacts/{contact_index}`

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:** (all fields optional)
```json
{
  "name": "Jane Smith",
  "phone": "+1555555555",
  "email": "janesmith@example.com",
  "relationship": "Mother"
}
```

**Response:**
```json
{
  "message": "Emergency contact updated successfully",
  "contact": {
    "name": "Jane Smith",
    "phone": "+1555555555",
    "email": "janesmith@example.com",
    "relationship": "Mother"
  }
}
```

### 4. Delete Emergency Contact
**DELETE** `/api/emergency-contacts/{contact_index}`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "message": "Emergency contact deleted successfully",
  "contact": {
    "name": "Jane Smith",
    "phone": "+1555555555",
    "email": "janesmith@example.com",
    "relationship": "Mother"
  }
}
```

### 5. Initiate Emergency Call
**POST** `/api/emergency-contacts/call/{contact_index}`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "message": "Emergency call initiated",
  "contact": {
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com",
    "relationship": "Brother"
  },
  "action": "call",
  "phone": "+1234567890"
}
```

### 6. Send Emergency Alert
**POST** `/api/emergency-contacts/alert`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "message": "Emergency alert sent to all contacts",
  "contacts": [
    {
      "name": "John Doe",
      "phone": "+1234567890",
      "email": "john@example.com",
      "relationship": "Brother"
    }
  ],
  "timestamp": "2026-01-27T12:00:00"
}
```

---

## Connected Users API

### Base URL: `/api/connected-users`

### 1. Get All Connected Users
**GET** `/api/connected-users`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "connected_users": [
    {
      "id": "507f1f77bcf86cd799439011",
      "name": "Alice Johnson",
      "email": "alice@example.com",
      "profile_image": "https://example.com/profile.jpg",
      "role": "user",
      "last_active": "2026-01-27T10:30:00"
    }
  ],
  "count": 1
}
```

### 2. Connect with User
**POST** `/api/connected-users/connect`

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:** (provide either email or user_id)
```json
{
  "email": "bob@example.com"
}
```
OR
```json
{
  "user_id": "507f1f77bcf86cd799439012"
}
```

**Response:**
```json
{
  "message": "Successfully connected",
  "user": {
    "id": "507f1f77bcf86cd799439012",
    "name": "Bob Smith",
    "email": "bob@example.com",
    "profile_image": null
  }
}
```

### 3. Disconnect User
**DELETE** `/api/connected-users/{user_id}`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "message": "Successfully disconnected",
  "user_id": "507f1f77bcf86cd799439012"
}
```

### 4. Search Users
**GET** `/api/connected-users/search?query={search_term}`

**Headers:**
- `Authorization: Bearer <token>`

**Query Parameters:**
- `query` (required): Search term (minimum 2 characters)

**Response:**
```json
{
  "results": [
    {
      "id": "507f1f77bcf86cd799439013",
      "name": "Charlie Brown",
      "email": "charlie@example.com",
      "profile_image": null,
      "role": "user"
    }
  ],
  "count": 1
}
```

### 5. Get User Status
**GET** `/api/connected-users/{user_id}/status`

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "507f1f77bcf86cd799439012",
  "name": "Bob Smith",
  "last_active": "2026-01-27T11:45:00",
  "status": "active"
}
```

---

## Error Responses

All endpoints may return these error responses:

### 400 Bad Request
```json
{
  "detail": "Error message describing the validation issue"
}
```

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

### 403 Forbidden
```json
{
  "detail": "Not connected with this user"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

---

## Usage Examples

### Example: Adding Emergency Contact
```python
import requests

url = "http://localhost:8000/api/emergency-contacts"
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}
data = {
    "name": "Emergency Contact",
    "phone": "+1234567890",
    "email": "emergency@example.com",
    "relationship": "Spouse"
}

response = requests.post(url, headers=headers, json=data)
print(response.json())
```

### Example: Connecting with User
```python
import requests

url = "http://localhost:8000/api/connected-users/connect"
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}
data = {
    "email": "friend@example.com"
}

response = requests.post(url, headers=headers, json=data)
print(response.json())
```

### Example: Sending Emergency Alert
```python
import requests

url = "http://localhost:8000/api/emergency-contacts/alert"
headers = {
    "Authorization": f"Bearer {access_token}"
}

response = requests.post(url, headers=headers)
print(response.json())
```

---

## Voice Command Integration

These endpoints integrate with the voice commands implemented in the mobile app:

**Emergency Contacts:**
- "show emergency contacts" → GET `/api/emergency-contacts`
- "add emergency contact" → Triggers UI to POST `/api/emergency-contacts`
- "emergency" / "SOS" → POST `/api/emergency-contacts/alert`

**Connected Users:**
- "connected users" → GET `/api/connected-users`
- "add connected user" → Triggers UI to POST `/api/connected-users/connect`
- Search functionality uses GET `/api/connected-users/search`

---

## Notes

1. **Emergency Contacts** are stored as an embedded list in the User document
2. **Connected Users** creates bidirectional connections between users
3. All endpoints require authentication via Bearer token
4. Emergency alert endpoint is designed to be extended with SMS/email notifications
5. The mobile app handles actual phone calls and notifications based on API responses
