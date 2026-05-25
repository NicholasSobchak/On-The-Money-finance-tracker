#include <catch2/catch_test_macros.hpp>

#include "account.h"

TEST_CASE("Account construction and getters")
{
  Account::resetIdCounter();
  Account acc("Test", 100.0, AccountType::Checking);

  REQUIRE(acc.getBalance() == 100.0);
  REQUIRE(acc.getType() == AccountType::Checking);
  REQUIRE(acc.getName() == "Test");
  REQUIRE(acc.getId() == 1);
}

TEST_CASE("Account auto-incrementing IDs")
{
  Account::resetIdCounter();
  Account a("First", 0.0, AccountType::Savings);
  Account b("Second", 0.0, AccountType::Checking);

  REQUIRE(b.getId() == a.getId() + 1);
}

TEST_CASE("Account deposit increases balance and returns transaction")
{
  Account::resetIdCounter();
  Account acc("Test", 100.0, AccountType::Checking);
  auto t = acc.deposit(50.0);

  REQUIRE(acc.getBalance() == 150.0);
  REQUIRE(t.getType() == TransactionType::Deposit);
  REQUIRE(t.getAmount() == 50.0);
  REQUIRE(t.getFromAccountId() == acc.getId());
  REQUIRE_FALSE(t.getToAccountId().has_value());
}

TEST_CASE("Account withdraw decreases balance and returns transaction")
{
  Account::resetIdCounter();
  Account acc("Test", 100.0, AccountType::Checking);
  auto t = acc.withdraw(30.0);

  REQUIRE(acc.getBalance() == 70.0);
  REQUIRE(t.getType() == TransactionType::Withdraw);
  REQUIRE(t.getAmount() == 30.0);
  REQUIRE(t.getFromAccountId() == acc.getId());
}

TEST_CASE("Account negative balance allowed")
{
  Account::resetIdCounter();
  Account acc("Credit", -500.0, AccountType::CreditCard);
  REQUIRE(acc.getBalance() == -500.0);
}

TEST_CASE("Account stores transaction history")
{
  Account::resetIdCounter();
  Account acc("Test", 100.0, AccountType::Checking);

  acc.deposit(50.0);
  acc.withdraw(30.0);
  acc.deposit(20.0);

  REQUIRE(acc.getTransactions().size() == 3);
  REQUIRE(acc.getTransactions()[0].getType() == TransactionType::Deposit);
  REQUIRE(acc.getTransactions()[0].getAmount() == 50.0);
  REQUIRE(acc.getTransactions()[1].getType() == TransactionType::Withdraw);
  REQUIRE(acc.getTransactions()[1].getAmount() == 30.0);
  REQUIRE(acc.getTransactions()[2].getType() == TransactionType::Deposit);
  REQUIRE(acc.getTransactions()[2].getAmount() == 20.0);
}

TEST_CASE("Account balance_at returns historical balance")
{
  Account::resetIdCounter();
  using namespace std::chrono;
  auto today = floor<days>(system_clock::now());
  auto yesterday = today - days{1};
  auto tomorrow = today + days{1};

  Account acc("Test", 100.0, AccountType::Checking);

  acc.deposit(50.0, "", yesterday);
  acc.withdraw(30.0, "", today);

  REQUIRE(acc.balanceAt(system_clock::time_point(yesterday - days{1})) == 100.0);
  REQUIRE(acc.balanceAt(system_clock::time_point(yesterday)) == 150.0);
  REQUIRE(acc.balanceAt(system_clock::time_point(tomorrow)) == 120.0);
}

TEST_CASE("Account total deposits and withdrawals")
{
  Account::resetIdCounter();
  Account acc("Test", 100.0, AccountType::Checking);

  REQUIRE(acc.totalDeposits() == 0.0);
  REQUIRE(acc.totalWithdrawals() == 0.0);
  REQUIRE(acc.netCashFlow() == 0.0);

  acc.deposit(50.0);
  acc.deposit(25.0);
  acc.withdraw(30.0);

  REQUIRE(acc.totalDeposits() == 75.0);
  REQUIRE(acc.totalWithdrawals() == 30.0);
  REQUIRE(acc.netCashFlow() == 45.0);
}
