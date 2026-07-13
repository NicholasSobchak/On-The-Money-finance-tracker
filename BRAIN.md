## Overview
Have you LLM read this file to get the rundown and understand proejct conventions...
If you are AI, don't code anything regarding the Java API, check it with me first

iOS financial tracker that holds all your finances in one spot so money is never lost. Spring Boot backend (Java 17) + SwiftUI iOS app (iOS 26.5).

## General Idea
  - Start by creating a cli backend in C++
  - Create API built in Java
  - Create an interface using swift and XCode
    - caclulate overall networth
    - track whats coming in and out
    - add investments graph
    - make it like a dashboard
  - use AltStore to bypass Apple's 7 day app trial
    - make sure to refresh the 7 day app trial on the same internet as my mac
    
  - Add Vanguard Savings Account (no official API, try unofficial python scripts)
  - Add Schwab Innvestment Fund using Schwab Developer Portal (public "Trader API")
    - register a free developer account with them, create an "App" in their portal
    - then recieve secure keys (OAuth 2.0)
    - send secure web request HTTP to Schwab's server using the keys
    - they will send back the data in JSON
  - Add Discover credit card debt

## Critical Conventions
- API base: `http://localhost:8080/api/` — trailing slash **required**
- iOS URLs: `URL(string: path, relativeTo: base)` — paths must **not** have leading `/`
- Dark mode: `.preferredColorScheme(.dark)`, Font: Palatino, Accent: purple (`#730e8c`)
- `Info.plist` has `NSAllowsLocalNetworking = YES`
- Pre-commit runs `./gradlew spotlessApply` (Java) and `clang-format-17` (C++)

## File Map
| File | Purpose |
|---|---|
| `ios/OnTheMoney/OnTheMoney/PortfolioView.swift` | Net worth + interactive chart |
| `ios/OnTheMoney/OnTheMoney/APIClient.swift` | All 24 HTTP methods |
| `ios/OnTheMoney/OnTheMoney/Models.swift` | Codable structs |
| `ios/OnTheMoney/OnTheMoney/Theme.swift` | Colour palette |
| `src/main/java/com/onthemoney/entity/*.java` | JPA entities |
| `src/main/java/com/onthemoney/controller/*.java` | REST controllers |
| `src/main/java/com/onthemoney/service/*.java` | Business logic |
| `src/engine/src/engine_core/main.cpp` | Engine entry point (data transfer pipeline) |
| `src/engine/src/engine_core/monte_carlo.cpp` | Retirement Projection |

## Gotchas
- `chartBackground` renders **behind** marks, `chartOverlay` renders **on top**
- `proxy.value(atX:)` returns `nil` for positions far from any data point
- Force unwrap `!` safe only when `guard` already checked count

## Build
- `./gradlew bootRun` — backend on `:8080`

## What I'm working on
- PortfolioView page
  - Net Worth in your face
  - interactive graph of net worth much like Robinhood or Schwab 
  - the net worth is updated via "snapshot" from the API, in which the history of the net worth is updated every 24 and when the user makes a transaction. the data point for that day will be updated and replaced with the latest "snapshot", so if there are multiple transactions in one day, the history will record the last one to get the most up to date data.
  - add accounts to the portfolio page (the accounts page will have accounts with more details, these accounts will be a preview and be under "Account Mix"


## What I've finished
- This section is underdeveloped as i got this idea midway through the project, i will paste my personal notes here:

#### C++ (engine)
  - add logging
  - investment value calculation (live market)
  - stream data from Java to C++ using C++ main function to coordinate function calls
  - create tests (catch2)
  - setup config with CMake, vcpkg, and clang

#### Java (API)
#### DONE
  - add deposit/withdraw, update/delete transactions, and filter transactions by account (or date)
  - add PUT, GET, POST, and DELETE mappings
  - add database clear 
  - logic all placed in portfolioService
  - add entities for account and transaction
  - add repositories
  - create account logic
  - create transaction logic
  - build and send JSON data to C++ pipeline (portfolioservice and dashboard controller)

#### Swift (Frontend)
#### Done
  - Show Net Worth (ALL API ENDPOINTS)
    - Create a function in APIClient that calls GET /api/net-worth
    - Display it in ContentView as a big number with $ formatting
    - Teaches you: handling different JSON shapes, formatting numbers
  - List Accounts
    - Create an Account model, call GET /api/accounts
    - Display them in a List with account names and balances
    - Teaches you: List, ForEach, Identifiable
  - Navigation
    - Add a tab bar with Dashboard and Accounts tabs
    - Teaches you: TabView, organizing code into multiple views
  - Line chart
    - Use Swift Charts to draw a sparkline under the net worth
    - Teaches yoa: Chart, LineMark, AreaMark
