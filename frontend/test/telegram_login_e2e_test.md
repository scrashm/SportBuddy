# End-to-End Telegram Login Testing Guide

## Overview
This document provides comprehensive testing procedures for the Telegram-based authentication system in the Sport Buddy app. The test verifies the complete flow from user authentication to JWT/profile retrieval.

## Test Environment Setup

### Prerequisites
1. **Physical Android/iOS Device** (required for Telegram app integration)
2. **Telegram App** installed on the test device
3. **Backend Server** running with valid configuration
4. **Test Telegram Bot** (@SportBuddyAuthBot) properly configured
5. **Database** (PostgreSQL) accessible and initialized

### Configuration Requirements

#### Backend (.env file)
```bash
# Database Configuration
DATABASE_URL=postgresql://username:password@host:5432/sportbuddy_db

# Telegram Bot Token (REQUIRED)
TELEGRAM_BOT_TOKEN=your_actual_bot_token_here

# Server Configuration
PORT=3000
NODE_ENV=development
```

#### Frontend (.env file)
```bash
# API Base URL
API_BASE_URL=http://your-backend-url:3000
```

## Test Scenarios

### Test Case 1: Complete Login Flow
**Objective**: Verify end-to-end Telegram login with real device

**Prerequisites**:
- Telegram app installed and user logged in
- Backend server running
- Test bot operational

**Steps**:
1. Launch the Sport Buddy app
2. Tap "Войти через Telegram" button
3. Verify app opens Telegram with correct deep link
4. In Telegram, tap "START" or send message to bot
5. Tap "Подтвердить вход" button in Telegram
6. Return to Sport Buddy app
7. Verify successful login and user profile display

**Expected Results**:
- ✅ App successfully opens Telegram
- ✅ Bot responds with confirmation button
- ✅ Backend receives confirmation and creates/updates user
- ✅ App polls status and receives JWT/user profile
- ✅ User is redirected to main app screen
- ✅ User profile data is correctly displayed

### Test Case 2: Network Error Handling
**Objective**: Test resilience to network issues

**Steps**:
1. Start login process
2. Disable internet connection during polling
3. Re-enable connection
4. Complete login in Telegram

**Expected Results**:
- ✅ App continues polling when connection restored
- ✅ Login completes successfully
- ✅ No crashes or undefined states

### Test Case 3: Timeout Scenarios
**Objective**: Test behavior when user doesn't complete login

**Steps**:
1. Start login process
2. Open Telegram but don't tap confirmation
3. Wait extended period
4. Return to app

**Expected Results**:
- ✅ App handles long polling gracefully
- ✅ User can restart login process
- ✅ No memory leaks or performance issues

## Authentication Flow Verification

### 1. Token Generation (Backend)
**Endpoint**: `POST /auth/telegram/start`

**Test Request**:
```bash
curl -X POST http://localhost:3000/auth/telegram/start
```

**Expected Response**:
```json
{
  "url": "https://t.me/SportBuddyAuthBot?start=token_[32-char-hex]",
  "token": "[32-char-hex-token]"
}
```

**Verification Points**:
- ✅ Token is 32 character hexadecimal string
- ✅ URL points to correct bot with token parameter
- ✅ Token stored in database with 'pending' status

### 2. Status Polling (App Side)
**Endpoint**: `GET /auth/telegram/status/:token`

**Test Request**:
```bash
curl http://localhost:3000/auth/telegram/status/[token]
```

**Response States**:
```json
// Initial state
{"status": "pending"}

// After bot interaction
{"status": "waiting_confirm"}

// After confirmation
{
  "status": "confirmed",
  "telegram_id": "123456789",
  "telegram_username": "testuser"
}
```

### 3. User Profile Retrieval
**Endpoint**: `GET /user/:telegram_id`

**Expected Response**:
```json
{
  "id": "uuid-string",
  "telegram_id": "123456789",
  "telegram_username": "testuser",
  "name": "Test User",
  "avatar_url": null,
  "bio": null,
  "sports": null,
  "interests": null,
  "pet": null,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

## Mobile App Testing Checklist

### UI/UX Verification
- [ ] Login button displays correctly
- [ ] Loading indicator appears during authentication
- [ ] Telegram app launches seamlessly
- [ ] Return to app transition is smooth
- [ ] User profile displays correctly after login
- [ ] Error messages are user-friendly

### Performance Testing
- [ ] App doesn't freeze during polling
- [ ] Memory usage remains stable
- [ ] Battery consumption is reasonable
- [ ] Network requests are optimized

### Edge Cases
- [ ] Telegram not installed (error handling)
- [ ] Invalid/expired tokens
- [ ] Network connectivity issues
- [ ] Bot service unavailable
- [ ] Database connection failures

## Database Verification

### Tables to Check
1. **login_tokens**
   - Token storage and status updates
   - Proper cleanup of expired tokens

2. **users**
   - User creation on first login
   - Existing user updates
   - Profile data integrity

### SQL Queries for Testing
```sql
-- Check login tokens
SELECT * FROM login_tokens ORDER BY created_at DESC LIMIT 10;

-- Check user creation
SELECT * FROM users WHERE telegram_id = 'YOUR_TELEGRAM_ID';

-- Verify data consistency
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM login_tokens WHERE status = 'confirmed';
```

## Security Testing

### Authentication Security
- [ ] Tokens are cryptographically secure (32-byte random)
- [ ] Tokens expire appropriately
- [ ] No sensitive data in logs
- [ ] SQL injection protection
- [ ] Cross-origin request protection

### Data Privacy
- [ ] Only necessary Telegram data is stored
- [ ] User can control profile visibility
- [ ] No unauthorized data access

## QA Notes and Issues

### Common Issues Found
1. **Deep Link Handling**: Ensure `url_launcher` handles Telegram URLs correctly
2. **Polling Efficiency**: Consider implementing exponential backoff
3. **Token Cleanup**: Implement automatic cleanup of expired tokens
4. **Error Recovery**: Improve user feedback on authentication failures

### Performance Observations
- Average login time: 10-15 seconds
- Network requests: 1 initial + polling requests every 3 seconds
- Memory usage: Stable during authentication flow

### User Experience Notes
- Users sometimes miss the confirmation button in Telegram
- Consider adding visual cues or tutorial for first-time users
- Loading states should be more informative

## Test Results Documentation

### Test Run Template
```
Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________
App Version: ___________

Test Case 1: Complete Login Flow
- Start Time: _______
- End Time: _______
- Result: PASS/FAIL
- Notes: ___________

Test Case 2: Network Error Handling
- Result: PASS/FAIL
- Notes: ___________

Test Case 3: Timeout Scenarios
- Result: PASS/FAIL
- Notes: ___________

Overall Assessment: ___________
```

## Screenshots Checklist

Capture screenshots for:
1. [ ] Initial login screen
2. [ ] Loading state during authentication
3. [ ] Telegram bot interaction
4. [ ] Confirmation message in Telegram
5. [ ] Successful login (main app screen)
6. [ ] User profile display
7. [ ] Any error states encountered

## Automation Opportunities

Consider implementing:
- Unit tests for AuthService methods
- Integration tests for API endpoints
- Widget tests for UI components
- End-to-end tests using Flutter Driver

## Recommendations

1. **Monitoring**: Implement analytics for login success/failure rates
2. **Logging**: Add structured logging for debugging authentication issues
3. **Fallback**: Consider alternative authentication methods
4. **UX**: Add progress indicators and better user guidance
5. **Security**: Regular security audits of authentication flow

---

**Note**: This document should be updated after each testing cycle with new findings and improvements.
