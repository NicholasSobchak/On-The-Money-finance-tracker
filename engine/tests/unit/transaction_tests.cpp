#include <catch2/catch_test_macros.hpp>

#include "transaction.h"

TEST_CASE("Transaction deposit")
{
  Transaction t(TransactionType::Deposit, 100.0, "Paycheck", 1);

  REQUIRE(t.get_type() == TransactionType::Deposit);
  REQUIRE(t.get_amount() == 100.0);
  REQUIRE(t.get_description() == "Paycheck");
  REQUIRE(t.get_from_account_id() == 1);
  REQUIRE_FALSE(t.get_to_account_id().has_value());
}

TEST_CASE("Transaction withdraw")
{
  Transaction t(TransactionType::Withdraw, 50.0, "Groceries", 2);

  REQUIRE(t.get_type() == TransactionType::Withdraw);
  REQUIRE(t.get_amount() == 50.0);
  REQUIRE(t.get_description() == "Groceries");
  REQUIRE(t.get_from_account_id() == 2);
  REQUIRE_FALSE(t.get_to_account_id().has_value());
}

TEST_CASE("Transaction transfer")
{
  Transaction t(TransactionType::Transfer, 200.0, "Moving money", 1, 2);

  REQUIRE(t.get_type() == TransactionType::Transfer);
  REQUIRE(t.get_amount() == 200.0);
  REQUIRE(t.get_from_account_id() == 1);
  REQUIRE(t.get_to_account_id() == std::optional<int>(2));
}

TEST_CASE("Transaction has a recent date")
{
  Transaction t(TransactionType::Deposit, 10.0, "Test", 1);

  auto now = std::chrono::system_clock::now();
  auto diff = now - t.get_date();
  auto secs = std::chrono::duration_cast<std::chrono::seconds>(diff).count();

  REQUIRE(secs < 5); // created within last 5 seconds
}
