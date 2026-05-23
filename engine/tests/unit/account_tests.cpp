#include <catch2/catch_test_macros.hpp>

#include "account.h"

TEST_CASE("Account construction and getters")
{
  Account acc("Test", 100.0, AccountType::Checking);

  REQUIRE(acc.get_balance() == 100.0);
  REQUIRE(acc.get_type() == AccountType::Checking);
  REQUIRE(acc.get_name() == "Test");
  REQUIRE(acc.get_id() == 1);
}

TEST_CASE("Account auto-incrementing IDs")
{
  Account a("First", 0.0, AccountType::Savings);
  Account b("Second", 0.0, AccountType::Checking);

  REQUIRE(b.get_id() == a.get_id() + 1);
}

TEST_CASE("Account deposit increases balance and returns transaction")
{
  Account acc("Test", 100.0, AccountType::Checking);
  auto t = acc.deposit(50.0);

  REQUIRE(acc.get_balance() == 150.0);
  REQUIRE(t.get_type() == TransactionType::Deposit);
  REQUIRE(t.get_amount() == 50.0);
  REQUIRE(t.get_from_account_id() == acc.get_id());
  REQUIRE_FALSE(t.get_to_account_id().has_value());
}

TEST_CASE("Account withdraw decreases balance and returns transaction")
{
  Account acc("Test", 100.0, AccountType::Checking);
  auto t = acc.withdraw(30.0);

  REQUIRE(acc.get_balance() == 70.0);
  REQUIRE(t.get_type() == TransactionType::Withdraw);
  REQUIRE(t.get_amount() == 30.0);
  REQUIRE(t.get_from_account_id() == acc.get_id());
}

TEST_CASE("Account negative balance allowed")
{
  Account acc("Credit", -500.0, AccountType::CreditCard);
  REQUIRE(acc.get_balance() == -500.0);
}
