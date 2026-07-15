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

---

# Finnhub Stock Market Integration Plan

## Overview
Live stock market data for the Stocks tab using Finnhub's free API. Provides real-time quotes, symbol search, market overview (S&P 500, NASDAQ, Dow), and a user-watchlist system with live prices.

## Prerequisites

### 1. Create Finnhub Account
1. Go to https://finnhub.io
2. Sign up for free
3. Get your API key from the dashboard

### 2. Add to `.env`
```
FINNHUB_API_KEY=your_api_key_here
```

### 3. Load in Backend
Already handled — `OnTheMoneyApplication.main()` loads `.env` via dotenv-java with `.ignoreIfMissing()`.

## Architecture

### Flow
```
iOS App → Backend /api/stocks/* → Finnhub REST API → 
Returns quote data → Backend passes through to iOS
```

### Finnhub API Endpoints Used
| Endpoint | Purpose | Free Tier |
|----------|---------|-----------|
| `GET /quote?symbol=AAPL` | Real-time quote (price, change, % change, high, low, open, prev close) | 60 calls/min |
| `GET /search?q=apple` | Symbol/name search | 60 calls/min |
| `GET /stock/profile2?symbol=AAPL` | Company name, logo, exchange | 60 calls/min |

**Base URL:** `https://finnhub.io/api/v1`
**Auth:** `?token=YOUR_API_KEY` (query parameter)

### Quote Response Format
```json
{
  "c": 195.50,    // current price
  "d": 2.30,      // change
  "dp": 1.19,     // percent change
  "h": 196.00,    // high of day
  "l": 193.20,    // low of day
  "o": 193.50,    // open price
  "pc": 193.20,   // previous close
  "t": 1689360000 // timestamp
}
```

### Search Response Format
```json
{
  "count": 10,
  "result": [
    {
      "description": "Apple Inc",
      "displaySymbol": "AAPL",
      "symbol": "AAPL",
      "type": "Common Stock"
    }
  ]
}
```

## Backend Implementation

### New Java Classes

1. **FinnhubService.java** (service)
   - `getQuote(symbol)` → calls Finnhub `/quote`
   - `searchSymbols(query)` → calls Finnhub `/search`
   - `getProfile(symbol)` → calls Finnhub `/stock/profile2`
   - Uses Java `HttpClient` (no external SDK needed)

2. **StockController.java** (controller)
   - `GET /api/stocks/quote?symbol=AAPL` — single stock quote
   - `GET /api/stocks/search?q=apple` — symbol search
   - `GET /api/stocks/overview` — market overview (SPY, QQQ, DIA hardcoded)
   - `GET /api/stocks/watchlist` — user's saved tickers with live quotes
   - `POST /api/stocks/watchlist?symbol=AAPL` — add to watchlist
   - `DELETE /api/stocks/watchlist/{symbol}` — remove from watchlist

3. **WatchlistEntity.java** (entity)
   - `id` (Long, auto-generated)
   - `symbol` (String, unique)
   - `addedDate` (LocalDateTime)

4. **WatchlistRepository.java** (repository)
   - `findBySymbol(String symbol)`
   - `deleteBySymbol(String symbol)`

### API Endpoints

#### GET /api/stocks/quote?symbol=AAPL
```json
{
  "symbol": "AAPL",
  "name": "Apple Inc",
  "currentPrice": 195.50,
  "change": 2.30,
  "percentChange": 1.19,
  "high": 196.00,
  "low": 193.20,
  "open": 193.50,
  "previousClose": 193.20
}
```

#### GET /api/stocks/search?q=apple
```json
{
  "results": [
    { "symbol": "AAPL", "description": "Apple Inc", "type": "Common Stock" }
  ]
}
```

#### GET /api/stocks/overview
Returns quotes for SPY, QQQ, DIA as market index proxies.
```json
{
  "indices": [
    { "symbol": "SPY", "name": "S&P 500", "price": 545.20, "change": 3.10, "percentChange": 0.57 },
    { "symbol": "QQQ", "name": "NASDAQ", "price": 480.50, "change": -1.20, "percentChange": -0.25 },
    { "symbol": "DIA", "name": "Dow Jones", "price": 395.80, "change": 0.80, "percentChange": 0.20 }
  ]
}
```

#### GET /api/stocks/watchlist
```json
[
  { "symbol": "AAPL", "name": "Apple Inc", "currentPrice": 195.50, "change": 2.30, "percentChange": 1.19, "addedDate": "2026-07-14" }
]
```

#### POST /api/stocks/watchlist?symbol=AAPL
Adds symbol to watchlist. Returns 201 Created.

#### DELETE /api/stocks/watchlist/{symbol}
Removes symbol from watchlist. Returns 204 No Content.

## iOS Implementation

### New Files

1. **StocksView.swift** (full rebuild)
   - Market Overview section: 3 index cards (SPY, QQQ, DIA)
   - Search bar with live results
   - Watchlist section with saved tickers
   - Swipe-to-delete on watchlist items
   - Tap search result to add to watchlist

2. **StockModels.swift** (models)
   ```swift
   struct StockQuote: Codable {
       let symbol: String
       let name: String
       let currentPrice: Double
       let change: Double
       let percentChange: Double
       let high: Double
       let low: Double
       let open: Double
       let previousClose: Double
   }

   struct MarketOverview: Codable {
       let indices: [StockQuote]
   }

   struct SearchResult: Codable {
       let symbol: String
       let description: String
       let type: String
   }
   ```

3. **APIClient.swift** (add methods)
   ```swift
   func getStockQuote(symbol: String) async throws -> StockQuote
   func searchStocks(query: String) async throws -> [SearchResult]
   func getMarketOverview() async throws -> MarketOverview
   func getWatchlist() async throws -> [StockQuote]
   func addToWatchlist(symbol: String) async throws
   func removeFromWatchlist(symbol: String) async throws
   ```

### UI Layout
```
┌─────────────────────────┐
│  Market Overview         │
│  ┌─────┐ ┌─────┐ ┌─────┐│
│  │ SPY │ │ QQQ │ │ DIA ││
│  │+0.5%│ │-0.3%│ │+0.2%││
│  └─────┘ └─────┘ └─────┘│
│                          │
│  🔍 Search stocks...     │
│  ┌──────────────────────┐│
│  │ AAPL  Apple Inc       ││
│  │ MSFT  Microsoft       ││
│  │ GOOGL Alphabet        ││
│  └──────────────────────┘│
│                          │
│  Your Watchlist           │
│  ┌──────────────────────┐│
│  │ AAPL   $195.50  +1.2%││
│  │ MSFT   $420.10  +0.8%││
│  └──────────────────────┘│
└─────────────────────────┘
```

## Rate Limiting
- Finnhub free tier: **60 calls/minute**
- Backend should cache quotes for 30 seconds to avoid hitting limits
- Watchlist refresh: fetch all symbols in a single request loop (10 symbols = 10 calls)

## Cost
- **Free tier**: 60 API calls/minute, real-time US stock quotes
- **No credit card required** for free tier
- Sufficient for personal use with a small watchlist
