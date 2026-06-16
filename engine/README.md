# C++ Engine

> **NOTE:** The engine binary is *not* available in CI or on fresh clones until built (see [Build](#build)). Without it, computation endpoints (`/api/net-worth`, etc.) return an error, but the Java API still starts and serves DB-backed endpoints (`/api/accounts`, `/api/transactions`) normally. The `GET /api/status` endpoint reports `"offline"` when the engine is missing.

The C++ engine is a subprocess that handles all financial computations (portfolio tracking, account management, transactions). It communicates with the Java API over stdin/stdout via newline-delimited JSON.

## Design: Stateless Computation

The engine is **stateless** — it does not persist data. On each request the Java side sends all necessary data alongside the action, the engine computes the result, and forgets everything.

**Why stateless instead of owning the data?**

| Approach | Tradeoff |
|----------|----------|
| **Stateful** (engine owns data in memory) | Fast single-lookup queries, but data is lost on restart unless the engine also writes to PostgreSQL — duplicating persistence logic across C++ and Java. |
| **Stateless** (Java owns data, engine computes) | Slightly more data sent over the pipe (microsecond cost at this scale), but the engine becomes a **pure function**: no side effects, no sync bugs, trivially testable, easy to reason about. |

For a personal finance tracker with at most hundreds of accounts/transactions, the overhead of sending data with each request is negligible. The reliability and simplicity win is decisive.

## Transport Protocol

The engine reads one **request** per line from **stdin**, processes it, and writes one **response** per line to **stdout**. Every message must be a single line ending in `\n`, and every response must be flushed immediately.

```
stdin  ──►  {"action":"getNetWorth"}\n
stdout ◄──  {"netWorth":1300.0}\n
```

If the response is not flushed, the Java side blocks forever waiting for it. Each request gets exactly one response before the next request is read — the protocol is strictly synchronous (the Java `send()` method is `synchronized`).

## Build

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build -j
./build/tests/run_tests
```

## JSON Protocol

Each request has an `"action"` field that routes to the appropriate handler. All dates are serialized as integer days since Unix epoch (1970-01-01).

In the examples below, `>` denotes a line written to **stdin** (request) and `<` denotes a line read from **stdout** (response).

## Enums

| AccountType | Value |
|---|---|
| `Checking` | 0 |
| `Savings` | 1 |
| `CreditCard` | 2 |
| `Investment` | 3 |
| `Loan` | 4 |

| TransactionType | Value |
|---|---|
| `Deposit` | 0 |
| `Withdraw` | 1 |
| `Transfer` | 2 |

## Actions

### `getNetWorth`
```
> {"action": "getNetWorth"}
< {"netWorth": 1300.0}
```

### `getTotalAssets`
```
> {"action": "getTotalAssets"}
< {"totalAssets": 2500.0}
```

### `totalLiabilities`
```
> {"action": "totalLiabilities"}
< {"totalLiabilities": 500.0}
```

### `inTheRed`
```
> {"action": "inTheRed"}
< {"inTheRed": false}
```

### `inTheGreen`
```
> {"action": "inTheGreen"}
< {"inTheGreen": true}
```

### `addAccount`
```
> {"action": "addAccount", "name": "Schwab", "balance": 5000.0, "accType": "Checking"}
< {"status": "ok"}
```

### `getAccount` — by ID
```
> {"action": "getAccount", "id": 1}
< {"status": "ok", "id": 1, "name": "Schwab", "balance": 5000.0, "type": 0}
< {"status": "error", "message": "account not found"}
```

### `getAccountByName`
```
> {"action": "getAccountByName", "name": "Schwab"}
< {"status": "ok", "id": 1, "name": "Schwab", "balance": 5000.0, "type": 0}
< {"status": "error", "message": "account not found"}
```

### `transfer` — optional `date` defaults to today
```
> {"action": "transfer", "from_account_id": 1, "to_account_id": 2, "amount": 100.0}
< {"status": "ok", "id": 1, "amount": 100.0, "type": 2, "date": 20100}

> {"action": "transfer", "from_account_id": 1, "to_account_id": 2, "amount": 100.0, "date": 20000}
< {"status": "ok", "id": 1, "amount": 100.0, "type": 2, "date": 20000}
```

### `getTransactions`
```
> {"action": "getTransactions", "start": 20000, "end": 20100}
< {"status": "ok", "transactions": [
      {"from_account_id": 1, "amount": 100.0, "type": 2, "description": "", "date": 20000, "to_account_id": 2}
  ]}
```

### `netWorthAt`
```
> {"action": "netWorthAt", "date": 20000}
< {"netWorth": 1500.0}
```
