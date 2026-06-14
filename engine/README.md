# C++ Engine

The C++ engine is a subprocess that handles all financial computations (portfolio tracking, account management, transactions). It communicates with the Java API over stdin/stdout via newline-delimited JSON.

## Build

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build -j
./build/tests/run_tests
```

## JSON Protocol

Each request has an `"action"` field that routes to the appropriate handler. All dates are serialized as integer days since Unix epoch (1970-01-01).

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
