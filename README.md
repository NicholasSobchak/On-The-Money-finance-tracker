<p align="center"><img src="On-The-Money_logo.png" alt="On-The-Money Logo" width=600 style="background: transparent;" /></p>

<h4 align="center">A Personal Finance Solution.</h4>
<p align="center">
  <a href="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions"><img src="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions/workflows/ci.yml/badge.svg" alt="Build and Test"></a>
</p>

#
### Description
On The Money is a personal finance tracker with a Java/Spring Boot API, PostgreSQL persistence, a C++ engine for heavy computations, and a SwiftUI iOS app. It tracks all your finances in one place — accounts, transactions, net worth history, credit score, stock market watchlist, and retirement projections.

### Features
- **Account Management** such as checking, savings, credit card, and investment accounts with full CRUD
- **Transactions** with date/description tracking
- **Net Worth Tracking** shows daily snapshots with interactive line chart and time range filters (1W, 1M, 3M, YTD, 1Y, ALL)
- **Monte Carlo Projections** is C++ engine runs 10,000 simulations to project portfolio growth over time with pessimistic/median/optimistic scenarios
- **Stock Market Integration** tracks live quotes and market indices (S&P 500, NASDAQ, Dow Jones, Russell 2000, VIX) via [Finnhub](https://finnhub.io/)
- **Plaid Bank Sync** — connect real bank and brokerage accounts via [Plaid](https://plaid.com/) for automatic transaction imports

# Building this project

### This project uses
  - C++20
  - Java 17
  - Swift / SwiftUI
  - [Spring Boot 3.3](https://spring.io/projects/spring-boot)
  - [PostgreSQL](https://www.postgresql.org/docs/)
  - [Docker](https://docs.docker.com/manuals/)
  - CMake
  - [Gradle](https://docs.gradle.org/current/userguide/userguide.html)
  - [nlohmann/json](https://json.nlohmann.me/)
  - [Plaid API](https://plaid.com/docs/api/) — bank account linking and transaction sync
  - [Finnhub API](https://finnhub.io/docs/api) — real-time stock quotes and market data
  - [Spring Security](https://spring.io/projects/spring-security) — API key authentication
  - [Nginx](https://nginx.org/) — reverse proxy for production deployment
  - clang (tidy/format)

### Project Structure

```
.
├── engine/
│   ├── include/
│   ├── src/
│   │   └── engine_core/
│   ├── tests/
│   │   └── unit/
│   ├── scripts/
│   └── vcpkg_installed/
├── ios/
│   └── OnTheMoney/
│       └── OnTheMoney/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/onthemoney/
│   │   │       ├── config/
│   │   │       ├── controller/
│   │   │       ├── entity/
│   │   │       ├── repository/
│   │   │       └── service/
│   │   └── resources/
│   └── test/
└── build.gradle
```

### Code Formatting (Pre-commit Hook)
To have consistent formatting across the project, configure `pre-commit`. It's a hook that automatically runs `clang-format` on your staged C++ files before each commit.

CI uses `clang-format-17` by default.

Setup Instructions:

1.  If you don't have it already, install `pre-commit`:
    ```bash
    # ubuntu
    sudo apt install pre-commit 

    # fedora 
    sudo dnf install pre-commit
    ```
2.  Install Git Hooks: From the project root, install the Git hooks:
    ```bash
    pre-commit install
    ```

## Environment Setup

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Required variables:
| Variable | Description |
|----------|-------------|
| `DB_PASSWORD` | PostgreSQL password |
| `PLAID_CLIENT_ID` | From [Plaid Dashboard](https://dashboard.plaid.com/team/keys) |
| `PLAID_SECRET` | From Plaid Dashboard |
| `PLAID_ENV` | `sandbox` (dev) or `production` (live banks) |
| `PLAID_REDIRECT_URI` | OAuth redirect URI for Plaid Link (optional) |
| `FINNHUB_API_KEY` | From [Finnhub](https://finnhub.io/register) |
| `API_KEY` | Generate with `openssl rand -hex 32` |

## Database

Start PostgreSQL via Docker:

```bash
docker compose up -d db
```

Tables are auto-created by Hibernate. To inspect:

```bash
docker exec -it onthemoney-db psql -U app -d onthemoney
dt  # show tables
q   # quit
```

## Build & Run

### C++ Engine

```bash
cd engine
cmake -S . -B build -DCMAKE_PREFIX_PATH="$(brew --prefix nlohmann-json);$(brew --prefix catch2)"
cmake --build build -j
./build/tests/run_tests
```

### Java API

```bash
# Build
./gradlew build

# Run
./gradlew bootRun

# Test (uses H2 in-memory DB, no PostgreSQL needed)
./gradlew test
```

### iOS App

Open `ios/OnTheMoney/OnTheMoney.xcodeproj` in Xcode and run on a simulator or device.

- **Debug builds** connect to `http://localhost:8080/api/`
- **Release builds** connect to the VPS at the configured address

## API Endpoints

All endpoints require `X-API-Key` header (except `/api/status` and `/`).

```http
GET  /api/
GET  /api/status

# Net Worth
GET  /api/net-worth
GET  /api/net-worth/history
POST /api/net-worth/snapshot
GET  /api/total-assets
GET  /api/total-liabilities

# Projections (Monte Carlo)
POST /api/project?initialBalance=10000&monthlyContribution=500&returnRate=7&years=30&simulations=10000

# Accounts
POST /api/accounts?name=Checking&balance=5000&accType=CHECKING
GET  /api/accounts
GET  /api/accounts?name=Checking
GET  /api/accounts/1
PUT  /api/accounts/1?name=Primary&balance=6000
DEL  /api/accounts/1
DEL  /api/accounts

# Transactions
POST /api/accounts/1/deposit?amount=500&description=paycheck&date=2026-06-19
POST /api/accounts/1/withdraw?amount=100&description=groceries&date=2026-06-20
GET  /api/transactions
GET  /api/transactions?start=2026-01-01&end=2026-12-31
GET  /api/transactions?accountId=1
PUT  /api/transactions/1?amount=250
DEL  /api/transactions/1

# Transfers
POST /api/transfers?fromAccountId=2&toAccountId=1&amount=2000&date=2026-06-19
# Credit Score
GET  /api/credit-score
POST /api/credit-score?score=742

# Plaid Integration
POST /api/plaid/link-token
POST /api/plaid/exchange-token
POST /api/plaid/sync
GET  /api/plaid/accounts
DEL  /api/plaid/items

# Stock Market (Finnhub)
GET  /api/stocks/quote?symbol=AAPL
GET  /api/stocks/search?query=apple
GET  /api/stocks/overview
GET  /api/stocks/candles?symbol=AAPL
GET  /api/stocks/watchlist
POST /api/stocks/watchlist?symbol=AAPL
DEL  /api/stocks/watchlist/AAPL
```

## JSON Protocol

See [`engine/README.md`](engine/README.md) for the complete JSON response structure.

For the Java API endpoints, requests and responses use JSON body format. Simple computations (net worth, assets, liabilities) are computed directly in Java. The Monte Carlo projection (`POST /api/project`) delegates to the C++ engine.

## Use & Distribution
_This project is for personal use only. It is not at all affiliated with any financial or institutional corporations. No gains or profits are made from this project, it is simply a tool for personal use._
