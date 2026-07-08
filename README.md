<p align="center"><img src="On-The-Money_logo.png" alt="On-The-Money Logo" width=600 style="background: transparent;" /></p>

<h4 align="center">A Personal Finance Solution.</h4>
<p align="center">
  <a href="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions"><img src="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions/workflows/ci.yml/badge.svg" alt="Build and Test"></a>
</p>

#
### Description
On the money is a personal finance tracker with a Java/Spring Boot API, PostgreSQL persistence, and a C++ engine for heavy computations.

### Features
  - Coming soon

# Building this project

### This project uses
  - C++20
  - Java 17
  - Swift
  - [Spring Boot 3.3](https://spring.io/projects/spring-boot)
  - SwiftUI
  - [PostgreSQL](https://www.postgresql.org/docs/)
  - [Docker](https://docs.docker.com/manuals/)
  - CMake
  - [Gradle](https://docs.gradle.org/current/userguide/userguide.html)
  - [nlohmann/json](https://json.nlohmann.me/)
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
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   └── test/
├── build.gradle
└── docker-compose.yml
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

## Database

Start PostgreSQL via Docker:

```bash
docker compose up -d
```

The `accounts` and `transactions` tables are auto-created by Hibernate. To inspect:

```bash
docker exec -it onthemoney-db psql -U app -d onthemoney
\dt  # show tables
\q   # quit
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

## API Endpoints

```http
GET  /api/
GET  /api/status
GET  /api/net-worth
GET  /api/total-assets
GET  /api/total-liabilities
GET  /api/in-the-red
GET  /api/in-the-green
POST /api/project?initialBalance=10000&monthlyContribution=500&returnRate=7&years=30&simulations=1000

POST /api/accounts?name=Checking&balance=5000&accType=CHECKING
GET  /api/accounts
GET  /api/accounts?name=Checking
GET  /api/accounts/1
PUT  /api/accounts/1?name=Primary&balance=6000
DEL  /api/accounts/1
DEL  /api/accounts

POST /api/accounts/1/deposit?amount=500&description=paycheck&date=2026-06-19
POST /api/accounts/1/withdraw?amount=100&description=groceries&date=2026-06-20
GET  /api/transactions
GET  /api/transactions?start=2026-01-01&end=2026-12-31
GET  /api/transactions?accountId=1
PUT  /api/transactions/1?amount=250
DEL  /api/transactions/1

POST /api/transfers?fromAccountId=2&toAccountId=1&amount=2000&date=2026-06-19
```

## JSON Protocol

See [`engine/README.md`](engine/README.md) for the complete JSON response structure.

For the Java API endpoints, requests and responses use JSON body format. Simple computations (net worth, assets, liabilities) are computed directly in Java. The Monte Carlo projection (`POST /api/project`) delegates to the C++ engine.

## Use & Distribution
_This project is for personal use only. It is not at all affiliated with any financial or institutional corporations. No gains or profits are made from this project, it is simply a tool for personal use._
