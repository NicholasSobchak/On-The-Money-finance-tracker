<p align="center"><img src="On-The-Money_logo.png" alt="On-The-Money Logo" width=600 style="background: transparent;" /></p>

<h4 align="center">A Personal Finance Solution.</h4>
<p align="center">
  <a href="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions"><img src="https://github.com/NicholasSobchak/On-The-Money-finance-tracker/actions/workflows/ci.yml/badge.svg" alt="Build and Test"></a>
</p>

#
### Description
On the money is a personal finance tracker built in C++. It uses a Java API and Springboot framework, and a IOS frontend app coded in Swift. 

### Features
  - coming soon

# Building this project

### This project uses
  - C++20
  - Java
  - Swift
  - PostgreSQL
  - [Springboot](https://spring.io/guides/gs/spring-boot)
  - Docker
  - CMake
  - Gradle
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
├── java-api/
│   └── src/
│       ├── main/
│       │   ├── java/
│       │   └── resources/
│       └── tests/
├── scripts/
```

### Code Formatting (Pre-commit Hook)
To have consistent formatting across the project, configure `pre-commit`. It's a hook that automatically runs `clang-format` on your staged C++ files before each commit.

CI uses `clang-format-17` by default.

Setup Instructions:

1.  Install `pre-commit`: If you don't have it already, install `pre-commit`:
    ```bash
    sudo apt install pre-commit
    ```
2.  Install Git Hooks: From the project root directory, install the Git hooks:
    ```bash
    pre-commit install
    ```

### Build

This project uses CMake + vcpkg (manifest mode via `vcpkg.json`) to fetch/build dependencies.

#### 1) Install dependencies

```bash
~/vcpkg/vcpkg install
```

#### 2) Configure

From the project root:

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake
```

#### 3) Build

```bash
cmake --build build -j
```

### Java-C++ DTO
```
ACCOUNT_NAME,TRANSACTION_TYPE,AMOUNT,DESCRIPTION

# Example

Schwab,Deposit,1250.00,Investment
Robinhood,Withdraw,45.50,Lunch
END
```

