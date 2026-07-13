# Plaid Bank Integration Plan

## Overview
Connect Security Plus FCU, Vanguard, and Schwab accounts using Plaid's unified API. Plaid supports 12,000+ institutions including all three of your banks.

## Prerequisites

### 1. Create Plaid Developer Account
1. Go to https://dashboard.plaid.com/signup
2. Sign up for free (sandbox environment for testing)
3. Get your credentials:
   - `PLAID_CLIENT_ID`
   - `PLAID_SECRET`

### 2. Add Plaid Java SDK to Backend
Add to `build.gradle`:
```groovy
implementation "com.plaid:plaid-java:9.0.0"
```

## Architecture

### Flow
```
iOS App → Plaid Link (web) → User connects bank → 
Plaid returns public_token → Backend exchanges for access_token → 
Backend stores access_token → Fetches balances/transactions
```

### Database Schema
Add new table `plaid_items`:
```sql
CREATE TABLE plaid_items (
    id SERIAL PRIMARY KEY,
    access_token VARCHAR(255) NOT NULL,
    item_id VARCHAR(255) NOT NULL,
    institution_name VARCHAR(255),
    institution_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Backend Implementation

### New Java Classes

1. **PlaidItemEntity.java** (entity)
   - id, accessToken, itemId, institutionName, institutionId, createdAt

2. **PlaidItemRepository.java** (repository)
   - findByInstitutionName, findAll

3. **PlaidService.java** (service)
   - createLinkToken(userId) → returns link_token for iOS
   - exchangePublicToken(publicToken) → stores access_token
   - getBalances() → fetches all account balances
   - getTransactions(startDate, endDate) → fetches transactions

4. **PlaidController.java** (controller)
   - POST /api/plaid/link-token
   - POST /api/plaid/exchange-token
   - GET /api/plaid/balances
   - GET /api/plaid/transactions

### API Endpoints

#### POST /api/plaid/link-token
Creates a link token for iOS Plaid Link integration.

**Request:**
```json
{
  "clientUserId": "user_123"
}
```

**Response:**
```json
{
  "linkToken": "link-sandbox-...",
  "expiration": "2026-07-14T12:00:00Z"
}
```

#### POST /api/plaid/exchange-token
Exchanges public_token from Plaid Link for permanent access_token.

**Request:**
```json
{
  "publicToken": "public-sandbox-...",
  "institutionId": "ins_3",
  "institutionName": "Charles Schwab"
}
```

**Response:**
```json
{
  "success": true,
  "itemId": "item_abc123"
}
```

#### GET /api/plaid/balances
Fetches real-time balances from all connected institutions.

**Response:**
```json
{
  "accounts": [
    {
      "accountId": "acc_123",
      "name": "Schwab Checking",
      "type": "depository",
      "subtype": "checking",
      "balance": 5000.00,
      "availableBalance": 4800.00,
      "institution": "Charles Schwab"
    }
  ],
  "totalBalance": 27100.00
}
```

#### GET /api/plaid/transactions
Fetches transactions from connected accounts.

**Query Params:**
- `start` (YYYY-MM-DD)
- `end` (YYYY-MM-DD)
- `accountId` (optional)

**Response:**
```json
{
  "transactions": [
    {
      "id": "tx_123",
      "date": "2026-07-13",
      "name": "Amazon Purchase",
      "amount": -49.99,
      "category": ["Shops", "Supermarkets and Groceries"],
      "accountName": "Schwab Checking"
    }
  ]
}
```

## iOS Implementation

### New Files

1. **PlaidLinkView.swift** (SwiftUI view)
   - Opens Plaid Link in WebView
   - Handles public_token exchange
   - Shows connection status

2. **PlaidService.swift** (API client extension)
   - createLinkToken()
   - exchangePublicToken()
   - getPlaidBalances()
   - getPlaidTransactions()

### Plaid Link Integration
Use Plaid's iOS SDK or WebView to open Link:
```swift
struct PlaidLinkView: UIViewRepresentable {
    let linkToken: String
    
    func makeUIView(context: Context) -> PLKLinkViewController {
        let configuration = PLKLinkConfiguration(token: linkToken)
        return PLKLinkViewController(configuration: configuration)
    }
}
```

### UI Flow
1. ProfileView → "Connect Bank" button
2. Opens Plaid Link
3. User selects institution (Schwab, Vanguard, Security Plus FCU)
4. User logs in through Plaid's secure UI
5. Plaid returns public_token
6. Backend exchanges for access_token
7. Account appears in AccountsView with real balance

## Security Considerations

1. **Never store bank credentials** - Plaid handles all authentication
2. **Store access_tokens encrypted** - Use AES-256 encryption
3. **Use HTTPS** - All API calls must be encrypted
4. **Implement token refresh** - Plaid tokens don't expire but can be invalidated
5. **Add rate limiting** - Prevent abuse of balance/transaction endpoints

## Environment Variables

Add to `.env`:
```
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret
PLAID_ENV=sandbox  # or production
```

## Testing

1. Use Plaid's sandbox environment with test credentials:
   - Institution: "First Platypus Bank" (sandbox)
   - Username: `user_good`
   - Password: `pass_good`

2. Test all three institution types:
   - Checking account (Security Plus FCU)
   - Savings/investment (Vanguard)
   - Brokerage (Schwab)

## Deployment Notes

1. **Switch to production** when ready:
   - Update `PLAID_ENV=production`
   - Use real Plaid credentials
   - Enable webhooks for real-time updates

2. **Webhooks** (optional enhancement):
   - `SYNC_UPDATES_AVAILABLE` - New transactions available
   - `ERROR` - Connection issues
   - `PENDING_EXPIRATION` - Token needs refresh

## Cost

- **Free tier**: 100 connections/month
- **Production**: $0.30/connection/month after free tier
- **Per API call**: Free for balance checks, minimal cost for transactions

## Next Steps

1. Sign up for Plaid developer account
2. Add plaid-java dependency to build.gradle
3. Create database migration for plaid_items table
4. Implement PlaidService.java
5. Add PlaidController endpoints
6. Build iOS PlaidLinkView
7. Test with sandbox credentials
8. Deploy to production
