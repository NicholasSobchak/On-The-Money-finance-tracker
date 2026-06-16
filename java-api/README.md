# Java API

Spring Boot 3.3 REST API that powers On The Money. It manages data in PostgreSQL and delegates financial computations to a C++ subprocess engine.

## Libraries

| Library | Purpose |
|---------|---------|
| **Spring Boot Web** | Embedded Tomcat server, REST controllers (`@RestController`, `@GetMapping`, etc.) |
| **Spring Boot Data JPA** | Hibernate ORM — maps Java entity classes to PostgreSQL tables, generates SQL automatically |
| **PostgreSQL JDBC Driver** | Low-level wire protocol from Java to the Docker Postgres instance |
| **dotenv-java** | Reads `.env` files for secret management (DB credentials, etc.) |
| **Jackson** | JSON serialization/deserialization (`ObjectMapper`, `JsonNode`, `valueToTree`) |
| **JUnit 5 + Spring Boot Test** | Integration testing with full application context loading |

### Data flow

1. **Mutations** (`POST /api/accounts`, `POST /api/transfers`) — Java writes directly to PostgreSQL via JPA. The engine is not involved.
2. **Queries** (`GET /api/accounts`, `GET /api/accounts/{id}`) — Java reads directly from PostgreSQL via JPA. The engine is not involved.
3. **Computations** (`GET /api/net-worth`, `GET /api/total-assets`, `GET /api/in-the-red`, `GET /api/net-worth-at`) — Java loads all accounts from PostgreSQL, wraps them in a JSON request with the action, sends them to the C++ engine over stdin, and returns the engine's response.

### Engine communication

The C++ engine runs as a subprocess launched by `PortfolioService` on application startup. They communicate over stdin/stdout pipes using newline-delimited JSON:

```
Request:  {"action":"getNetWorth","accounts":[{"name":"Checking","balance":5000.0,"accType":"Checking"},...]}\n
Response: {"netWorth":4800.0}\n
```

Each write to stdin is flushed; each response on stdout is flushed. The protocol is strictly synchronous — one request in, one response out. The Java side locks (`synchronized`) to prevent concurrent access.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/` | Greeting |
| `GET` | `/api/status` | Engine status (online/offline) |
| `GET` | `/api/net-worth` | Total net worth |
| `GET` | `/api/total-assets` | Sum of positive balances |
| `GET` | `/api/total-liabilities` | Sum of negative balances |
| `GET` | `/api/in-the-red` | Net worth negative? |
| `GET` | `/api/in-the-green` | Net worth non-negative? |
| `GET` | `/api/net-worth-at?date=2026-06-01` | Historical net worth |
| `GET` | `/api/accounts` | All accounts (or `?name=Checking`) |
| `GET` | `/api/accounts/{id}` | Account by ID |
| `POST` | `/api/accounts?name=X&balance=Y&accType=Z` | Create account |
| `POST` | `/api/transfers?fromAccountId=X&toAccountId=Y&amount=Z` | Transfer between accounts |
| `GET` | `/api/transactions?start=2026-01-01&end=2026-12-31` | List transactions |
