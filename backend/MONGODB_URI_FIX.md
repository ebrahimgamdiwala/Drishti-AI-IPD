# MongoDB URI Special Characters Fix

## ✅ Issue Fixed

**Error**: `Username and password must be escaped according to RFC 3986`

**Cause**: The password `pandya@123` contains a `@` symbol which is a special character in URLs.

**Solution**: URL-encode the special character: `@` → `%40`

---

## 🔧 What Was Changed

### Before (Broken):
```
MONGO_URI=mongodb+srv://cursora958_db_user:pandya@123@cluster0.1z2x7dh.mongodb.net/?appName=Cluster0
```

### After (Fixed):
```
MONGO_URI=mongodb+srv://cursora958_db_user:pandya%40123@cluster0.1z2x7dh.mongodb.net/?appName=Cluster0
```

---

## 📝 Common Special Characters to Encode

If your MongoDB password contains any of these characters, you must URL-encode them:

| Character | URL Encoded | Example Password | Encoded Password |
|-----------|-------------|------------------|------------------|
| `@` | `%40` | `pass@123` | `pass%40123` |
| `:` | `%3A` | `pass:word` | `pass%3Aword` |
| `/` | `%2F` | `pass/word` | `pass%2Fword` |
| `?` | `%3F` | `pass?123` | `pass%3F123` |
| `#` | `%23` | `pass#123` | `pass%23123` |
| `[` | `%5B` | `pass[123` | `pass%5B123` |
| `]` | `%5D` | `pass]123` | `pass%5D123` |
| `%` | `%25` | `pass%123` | `pass%25123` |
| `&` | `%26` | `pass&word` | `pass%26word` |
| `=` | `%3D` | `pass=word` | `pass%3Dword` |
| `+` | `%2B` | `pass+word` | `pass%2Bword` |
| ` ` (space) | `%20` | `pass word` | `pass%20word` |

---

## 🐍 Python Script to Encode Password

If you need to encode a password programmatically:

```python
from urllib.parse import quote_plus

password = "pandya@123"
encoded_password = quote_plus(password)
print(f"Original: {password}")
print(f"Encoded: {encoded_password}")
# Output: pandya%40123
```

---

## 🧪 Testing

Now you can start the server:

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
✅ Connected to MongoDB (db='...')
🚀 Drishti AI FastAPI Server is running!
```

---

## 🔐 Security Note

**Never commit your `.env` file to version control!**

Make sure `.env` is in your `.gitignore`:

```gitignore
# Environment variables
.env
.env.local
.env.*.local
```

---

## 📚 References

- [RFC 3986 - URI Generic Syntax](https://www.rfc-editor.org/rfc/rfc3986)
- [MongoDB Connection String URI Format](https://www.mongodb.com/docs/manual/reference/connection-string/)
- [Python urllib.parse.quote_plus](https://docs.python.org/3/library/urllib.parse.html#urllib.parse.quote_plus)

---

**Status**: ✅ Fixed
**Date**: February 7, 2026
