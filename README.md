# On-The-Money-finance-tracker
On the money is a personal finance tracker for individuals looking for financial solace

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
