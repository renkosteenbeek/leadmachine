# Microsoft Graph API - LeadMachine Documentation

## Overview
This document describes the tested Microsoft Graph API endpoints for the LeadMachine Swift CLI application.

**Mailbox**: renko.steenbeek@configurewise.com
**Authentication**: OAuth 2.0 Client Credentials Flow
**Required Permissions**: Mail.Read, Mail.Send, Mail.ReadWrite

---

## Authentication

### Endpoint
```
POST https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token
```

### Request
```http
Content-Type: application/x-www-form-urlencoded

client_id={CLIENT_ID}
&client_secret={CLIENT_SECRET}
&scope=https://graph.microsoft.com/.default
&grant_type=client_credentials
```

### Response
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJub...",
  "expires_in": 3599,
  "token_type": "Bearer"
}
```

### Notes
- Token expires after ~1 hour (3599 seconds)
- Cache token and refresh before expiration
- Use token in Authorization header: `Bearer {access_token}`

---

## 1. List All Mailbox Folders

### Endpoint
```
GET https://graph.microsoft.com/v1.0/users/{userEmail}/mailFolders
```

### Query Parameters
- `$select`: Fields to return (id,displayName,parentFolderId,totalItemCount,unreadItemCount)
- `$top`: Max number of results (default: 10, max: 999)

### Request Example
```http
GET /v1.0/users/renko.steenbeek@configurewise.com/mailFolders?$select=id,displayName,totalItemCount&$top=50
Authorization: Bearer {token}
```

### Response Example
```json
{
  "value": [
    {
      "id": "AQMkADllMmZmADczNi04OTE3...",
      "displayName": "Inbox",
      "totalItemCount": 2397,
      "unreadItemCount": 354,
      "childFolderCount": 4
    }
  ]
}
```

### Notes
- Inbox ID: `AQMkADllMmZmADczNi04OTE3LTQ2MWMtOWMxMi0wYjM1ZWYyYjJjNWIALgAAA82m2bhKHwNBo4BF0QpqwiMBAA9heOIAgutAoBg2PZyEdFkAAAIBDAAAAA==`
- Always check `childFolderCount` to see if folder has subfolders

---

## 2. List Subfolders

### Endpoint
```
GET https://graph.microsoft.com/v1.0/users/{userEmail}/mailFolders/{folderId}/childFolders
```

### Request Example
```http
GET /v1.0/users/renko.steenbeek@configurewise.com/mailFolders/{INBOX_ID}/childFolders
Authorization: Bearer {token}
```

### Response Example
```json
{
  "value": [
    {
      "id": "AAMkADllMmZmNzM2LTg5...",
      "displayName": "leadmachine",
      "totalItemCount": 6,
      "unreadItemCount": 0
    }
  ]
}
```

### LeadMachine Folder Structure
```
Inbox
└── leadmachine (ID: AAMkADllMmZmNzM2LTg5MTctNDYxYy05YzEyLTBiMzVlZjJiMmM1YgAuAAAAAADNptm4Sh8DQaOARdEKasIjAQAPYXjiAILrQKAYNj2chHRZAAFinm3eAAA=)
    └── processed (ID: AAMkADllMmZmNzM2LTg5MTctNDYxYy05YzEyLTBiMzVlZjJiMmM1YgAuAAAAAADNptm4Sh8DQaOARdEKasIjAQAPYXjiAILrQKAYNj2chHRZAAFinm3fAAA=)
```

---

## 3. Read Emails from Folder

### Endpoint
```
GET https://graph.microsoft.com/v1.0/users/{userEmail}/mailFolders/{folderId}/messages
```

### Query Parameters
- `$select`: Fields to return
- `$top`: Max messages (default: 10)
- `$orderby`: Sort order (e.g., "receivedDateTime DESC")
- `$filter`: Filter expression (e.g., "isRead eq false")

### Request Example
```http
GET /v1.0/users/renko.steenbeek@configurewise.com/mailFolders/{LEADMACHINE_ID}/messages
  ?$select=id,subject,from,receivedDateTime,body,bodyPreview,isRead
  &$top=50
  &$orderby=receivedDateTime DESC
Authorization: Bearer {token}
```

### Response Example
```json
{
  "value": [
    {
      "id": "AAMkADllMmZmNzM2LTg5MTctNDYxYy05YzEyLTBiMzVlZjJiMmM1YgBGAAAAAADNptm4...",
      "subject": "Lead Machine CRM H lead 0157646",
      "from": {
        "emailAddress": {
          "address": "leads@leadmachine.eu",
          "name": "Lead Machine"
        }
      },
      "receivedDateTime": "2025-11-06T14:45:15Z",
      "isRead": true,
      "bodyPreview": "Nieuwe CRM H-lead Deze lead wordt maximaal 7 keer verkocht...",
      "body": {
        "contentType": "HTML",
        "content": "<html>...</html>"
      }
    }
  ]
}
```

### Notes
- Body can be HTML or Text (check `contentType`)
- Use `bodyPreview` for quick text summary (max ~256 chars)
- Date format is ISO 8601 UTC

---

## 4. Create Folder

### Endpoint
```
POST https://graph.microsoft.com/v1.0/users/{userEmail}/mailFolders/{parentFolderId}/childFolders
```

### Request Example
```http
POST /v1.0/users/renko.steenbeek@configurewise.com/mailFolders/{LEADMACHINE_ID}/childFolders
Authorization: Bearer {token}
Content-Type: application/json

{
  "displayName": "processed"
}
```

### Response
Returns the created folder object with ID.

### Notes
- Returns 409 Conflict if folder already exists
- Check for existing folder first to avoid errors

---

## 5. Move Email

### Endpoint
```
POST https://graph.microsoft.com/v1.0/users/{userEmail}/messages/{messageId}/move
```

### Request Example
```http
POST /v1.0/users/renko.steenbeek@configurewise.com/messages/{MESSAGE_ID}/move
Authorization: Bearer {token}
Content-Type: application/json

{
  "destinationId": "{PROCESSED_FOLDER_ID}"
}
```

### Response
Returns the moved message with NEW message ID.

### Important Notes
- **Message ID changes after move!**
- Original message ID becomes invalid (404 Not Found)
- Message is REMOVED from source folder
- Message does NOT reappear in source folder after move
- Use the new ID from response for further operations

### Example
```
Original ID:  AAMkADllMmZmNzM2...F5AAA=
After move:   AAMkADllMmZmNzM2...16AAA=  (different!)
```

---

## 6. Forward Email

### Endpoint
```
POST https://graph.microsoft.com/v1.0/users/{userEmail}/messages/{messageId}/forward
```

### Request Example
```http
POST /v1.0/users/renko.steenbeek@configurewise.com/messages/{MESSAGE_ID}/forward
Authorization: Bearer {token}
Content-Type: application/json

{
  "comment": "=== CPQ LEAD ANALYSE ===\n\nDit is een interessante lead.\n\n=== ORIGINELE EMAIL ===",
  "toRecipients": [
    {
      "emailAddress": {
        "address": "renko1985@gmail.com"
      }
    }
  ]
}
```

### Response
Returns 202 Accepted (no body)

### Notes
- `comment` appears ABOVE the original email
- Original email is included automatically as forwarded content
- Supports multiple recipients in `toRecipients` array
- Use `\n` for newlines in comment
- No response body, just HTTP 202 status

---

## Error Handling

### Common Errors

#### 401 Unauthorized
```json
{
  "error": {
    "code": "InvalidAuthenticationToken",
    "message": "Access token has expired."
  }
}
```
**Solution**: Refresh access token

#### 403 Forbidden
```json
{
  "error": {
    "code": "ErrorAccessDenied",
    "message": "Access is denied."
  }
}
```
**Solution**: Check API permissions in Azure Portal

#### 404 Not Found
```json
{
  "error": {
    "code": "ErrorItemNotFound",
    "message": "The specified object was not found."
  }
}
```
**Solution**: Message was moved/deleted, or folder doesn't exist

#### 429 Too Many Requests
```json
{
  "error": {
    "code": "RequestThrottled",
    "message": "Too many requests."
  }
}
```
**Solution**: Implement exponential backoff, wait and retry

---

## Rate Limits

- **Default**: 10,000 requests per 10 minutes per app
- **Burst**: ~100 requests per second per user
- **Headers**: Check `Retry-After` header on 429 errors

---

## Swift Implementation Notes

### Date Parsing
```swift
let formatter = ISO8601DateFormatter()
let date = formatter.date(from: "2025-11-06T14:45:15Z")
```

### URL Encoding
```swift
let encoded = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
```

### Folder ID Storage
Store folder IDs after first lookup to avoid repeated searches:
- leadmachine folder ID
- processed folder ID

### Token Management
```swift
struct TokenCache {
    var token: String
    var expiresAt: Date

    var isValid: Bool {
        Date() < expiresAt.addingTimeInterval(-300) // 5 min buffer
    }
}
```

---

## Complete Workflow Example

```
1. Authenticate
   POST /oauth2/v2.0/token
   → Get access token

2. Find folders
   GET /mailFolders (get Inbox)
   GET /mailFolders/{inbox}/childFolders (get leadmachine)
   GET /mailFolders/{leadmachine}/childFolders (get processed)

3. Read emails
   GET /mailFolders/{leadmachine}/messages?$top=50

4. For each email:
   a. Analyze with LLM
   b. If lead:
      POST /messages/{id}/forward (to renko1985@gmail.com)
   c. Move to processed:
      POST /messages/{id}/move (to processed folder)

5. Repeat periodically (daemon mode)
```

---

## Testing Results

✅ All API operations tested successfully on 2025-11-06:
- List folders: ✓
- Find subfolders: ✓
- Read emails: ✓ (5 emails found)
- Create folder: ✓
- Move email: ✓
- Verify move (email gone from source): ✓
- Forward email: ✓

Ready for Swift implementation!
