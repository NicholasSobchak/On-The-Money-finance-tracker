## Overview
iOS finance tracker — all your finances in one spot so money is never lost.
**Stack**: C++ engine + Java 17 Spring Boot backend (`:8080`) + SwiftUI iOS app (iOS 26.5)

**If you are AI, don't code anything regarding the Java API, check it with me first.**

## Stack
- **C++ engine**: `src/engine/src/engine_core/` — data pipeline, monte carlo projections
- **Java backend**: `src/main/java/com/onthemoney/` — Spring Boot, PostgreSQL via Docker
- **iOS frontend**: `ios/OnTheMoney/OnTheMoney/` — SwiftUI, dark mode only

## Critical Conventions
- API base: `http://localhost:8080/api/` — trailing slash **required**
- iOS URLs: `URL(string: path, relativeTo: base)` — paths must **not** have leading `/`
- Dark mode: `.preferredColorScheme(.dark)`, Font: Palatino, Accent: white (`themeAccent`)
- Tab bar: Custom (native hidden via `.toolbar(.hidden, for: .tabBar)`) — black background, white selected, grey unselected
- `Info.plist` has `NSAllowsLocalNetworking = YES`
- Pre-commit runs `./gradlew spotlessApply` (Java) and `clang-format-17` (C++)
- Database: PostgreSQL via Docker (`docker compose`), user `app`, DB `onthemoney`
- Hibernate: `ddl-auto=update` — entity classes auto-create tables
- App is read-only — no real money movement, transfer/deposit/withdraw only update local DB
- Plaid SDK v9.0.0 (`com.plaid:plaid-java:9.0.0`), credentials in `.env`
- Finnhub stock API planned but not yet implemented

## Theme (Theme.swift)
```swift
themeBackground = Color(red: 0.04, green: 0.04, blue: 0.04)  // main bg
themeSurface   = Color(red: 0.1, green: 0.1, blue: 0.1)      // card bg
themeSurface2  = Color(red: 0.15, green: 0.13, blue: 0.16)   // secondary bg
themeText      = Color(red: 0.88, green: 0.85, blue: 0.80)   // primary text
themeAccent    = Color.white                                    // accent
themeMuted     = Color(red: 0.55, green: 0.53, blue: 0.51)   // muted/secondary text
```

## File Map — iOS
| File | Purpose |
|---|---|
| `OnTheMoneyApp.swift` | App entry, splash screen (3.5s), theme setup |
| `ContentView.swift` | Custom tab bar (Portfolio/Accounts/Stocks/Profile) |
| `PortfolioView.swift` | Net worth display, interactive chart, time range selector, account mix |
| `AccountsView.swift` | Account list with search, Plaid Link flow, chevron to detail |
| `AccountDetailView.swift` | Custom top bar, centered header, transaction list, search + deposit/withdraw filter |
| `AccountEditView.swift` | Edit name, account #, balance (read-only), interest %, dividend %, type, save/delete modals |
| `TransactionDetailView.swift` | Custom top bar, large colored amount, editable description/date, type display |
| `StocksView.swift` | Placeholder — "Coming Soon" |
| `ProfileView.swift` | Full profile page with account, preferences, data, about, logout |
| `PlaidLinkView.swift` | WKWebView for Plaid Link |
| `APIClient.swift` | All HTTP methods (accounts, transactions, Plaid, net worth) |
| `Models.swift` | Account, Transaction, NetWorthResponse, etc. |
| `Theme.swift` | Color palette |

## File Map — Java Backend
| File | Purpose |
|---|---|
| `entity/AccountEntity.java` | JPA entity with `plaidAccountId` |
| `entity/TransactionEntity.java` | JPA entity with TransactionType enum (DEPOSIT/WITHDRAW/TRANSFER) |
| `entity/PlaidItemEntity.java` | Plaid item storage |
| `controller/DashboardController.java` | Account CRUD, transaction CRUD |
| `controller/PlaidController.java` | 8 endpoints including DELETE /plaid/accounts |
| `service/PortfolioService.java` | Account/transaction business logic |
| `service/PlaidService.java` | Full Plaid service with Gson patching |

## File Map — C++ Engine
| File | Purpose |
|---|---|
| `src/engine/src/engine_core/main.cpp` | Engine entry point (data transfer pipeline) |
| `src/engine/src/engine_core/monte_carlo.cpp` | Retirement projection |

## Gotchas
- `chartBackground` renders **behind** marks, `chartOverlay` renders **on top**
- `proxy.value(atX:)` returns `nil` for positions far from any data point
- Force unwrap `!` safe only when `guard` already checked count
- `URL(string:relativeTo:)` is fussy — paths must NOT start with `/`
- Plaid Gson patching: must patch via reflection on `ApiClient.json` field, then rebuild adapter
- iOS 26 simulator WKWebView broken — Plaid Link only works on real devices
- `accountNumber` and `interestRate` are iOS-only display fields, not stored in Java backend

## Build & Run
- `docker compose down && docker compose build --no-cache && docker compose up -d` — rebuild backend
- `./gradlew bootRun` — backend on `:8080`
- Xcode: build and run on simulator or device
- `./gradlew spotlessApply` — Java formatting
- `clang-format-17 -i <file>` — C++ formatting

## What's Done
- PortfolioView: net worth, interactive chart, time range, account mix
- AccountsView: list, search, Plaid Link, delete
- AccountDetailView: custom nav, centered header, transaction list with search + deposit/withdraw filter
- AccountEditView: all fields editable with pencil icons, save/delete custom modals, dividend rate
- TransactionDetailView: editable description/date, type display, delete modal
- ProfileView: full profile page with sections (account, preferences, data, about, logout)
- Plaid backend: entities, service (8 methods), controller (8 endpoints)
- Custom tab bar: black, no bubble, white/grey icons
- Launch screen: black background with logo (SwiftUI overlay, 3.5s)
- Theme: all colors defined, themeMuted brightened

## What's Next
- Finnhub stock integration (market overview + watchlist) — plan in `API_INTEGRATION_PLAN.md`
- StocksView: live market data, search, watchlist
- Schwab Developer Portal integration (OAuth 2.0, Trader API)
- Vanguard savings account (unofficial Python scripts)
- Discover credit card debt tracking
- AltStore 7-day refresh workaround
