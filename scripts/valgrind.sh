#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
BUILD_DIR="$ENGINE_DIR/build"

echo "=== Running Valgrind on C++ Engine ==="

# Build with debug symbols
echo "Building with debug symbols..."
cmake -S "$ENGINE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_TOOLCHAIN_FILE="$ENGINE_DIR/vcpkg/scripts/buildsystems/vcpkg.cmake"
cmake --build "$BUILD_DIR" -j"$(nproc)"

VALGRIND_FLAGS="--leak-check=full --show-leak-kinds=all --track-origins=yes --verbose --log-file=valgrind_output.txt"

# Feed test CSV data into the finance executable under valgrind
echo "Running finance executable under valgrind with test data..."
valgrind $VALGRIND_FLAGS "$BUILD_DIR/src/finance" <<'EOF'
Checking,Deposit,1000.00,Initial deposit
Savings,Deposit,500.00,Starting balance
Checking,Withdraw,200.00,Groceries
CreditCard,Deposit,150.00,Refund
EOF

echo ""
echo "=== Valgrind complete ==="
echo "Output saved to valgrind_output.txt"
echo ""
echo "=== Summary (definite leaks) ==="
grep -A5 "definitely lost:" valgrind_output.txt || echo "No definite leaks found!"
