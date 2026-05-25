#include <catch2/catch_test_macros.hpp>

#include "transaction.h"

TEST_CASE("Transaction deposit")
{
  Transaction t(TransactionType::Deposit, 100.0, "Paycheck", 1);

  REQUIRE(t.getType() == TransactionType::Deposit);
  REQUIRE(t.getAmount() == 100.0);
  REQUIRE(t.getDescription() == "Paycheck");
  REQUIRE(t.getFromAccountId() == 1);
  REQUIRE_FALSE(t.getToAccountId().has_value());
}

TEST_CASE("Transaction withdraw")
{
  Transaction t(TransactionType::Withdraw, 50.0, "Groceries", 2);

  REQUIRE(t.getType() == TransactionType::Withdraw);
  REQUIRE(t.getAmount() == 50.0);
  REQUIRE(t.getDescription() == "Groceries");
  REQUIRE(t.getFromAccountId() == 2);
  REQUIRE_FALSE(t.getToAccountId().has_value());
}

TEST_CASE("Transaction transfer")
{
  Transaction t(TransactionType::Transfer, 200.0, "Moving money", 1, 2);

  REQUIRE(t.getType() == TransactionType::Transfer);
  REQUIRE(t.getAmount() == 200.0);
  REQUIRE(t.getFromAccountId() == 1);
  REQUIRE(t.getToAccountId() == std::optional<int>(2));
}

TEST_CASE("Transaction has a recent date")
{
  using namespace std::chrono;
  auto today = floor<days>(system_clock::now());

  Transaction t(TransactionType::Deposit, 10.0, "Test", 1);

  REQUIRE(t.getDate() == today);
}
