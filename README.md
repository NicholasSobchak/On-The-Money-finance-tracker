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
  - Java 17, Spring Boot 3.3
  - Swift
  - [PostgreSQL](https://www.postgresql.org/docs/)
  - Docker
  - CMake
  - [Gradle](https://docs.gradle.org/current/userguide/userguide.html)
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
│   └── vcpkg_installed/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   └── test/
├── gradle/
├── build.gradle
├── gradlew
├── gradlew.bat
├── scripts/
├── docker-compose.yml
└── On-The-Money_logo.png
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
\dt
\q
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

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/` | Greeting |
| `GET` | `/api/status` | Engine status (online/offline) |
| `GET` | `/api/net-worth` | Total net worth |
| `GET` | `/api/total-assets` | Sum of positive balances |
| `GET` | `/api/total-liabilities` | Sum of negative balances |
| `GET` | `/api/in-the-red` | Net worth negative? |
| `GET` | `/api/in-the-green` | Net worth non-negative? |
| `POST` | `/api/project` | Monte Carlo retirement projection |
| `GET` | `/api/accounts` | All accounts (or `?name=Checking`) |
| `GET` | `/api/accounts/{id}` | Account by ID |
| `POST` | `/api/accounts?name=X&balance=Y&accType=Z` | Create account |
| `PUT` | `/api/accounts/{id}?name=X&balance=Y&accType=Z` | Update account |
| `DELETE` | `/api/accounts` | Delete all accounts + transactions |
| `DELETE` | `/api/accounts/{id}` | Delete account by ID |
| `POST` | `/api/transfers` | Transfer between accounts |
| `GET` | `/api/transactions` | List transactions by date range |

## JSON Protocol

See [`engine/README.md`](engine/README.md) for the complete JSON response structure.

For the Java API endpoints, requests and responses use JSON body format. Simple computations (net worth, assets, liabilities) are computed directly in Java. The Monte Carlo projection (`POST /api/project`) delegates to the C++ engine.

# API Example
...

# Use & Distribution
_This project is for personal use only. It is not at all affiliated with any financial or institutional corporations. No gains or profits are made from this project, it is simply a tool for personal use._
