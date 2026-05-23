#include <catch2/catch_test_macros.hpp>

#include "portfolio.h"

TEST_CASE("Portfolio net worth")
{
  Portfolio p;

  p.add_account(Account("Checking", 500.0, AccountType::Checking));
  p.add_account(Account("Savings", 1000.0, AccountType::Savings));
  p.add_account(Account("Credit Card", -200.0, AccountType::CreditCard));

  REQUIRE(p.total_assets() == 1500.0);
  REQUIRE(p.total_liabilities() == -200.0);
  REQUIRE(p.net_worth() == 1300.0);
  REQUIRE(p.in_the_green());
  REQUIRE_FALSE(p.in_the_red());
}

TEST_CASE("Portfolio in the red")
{
  Portfolio p;
  p.add_account(Account("Loan", -5000.0, AccountType::Loan));
  p.add_account(Account("Checking", 100.0, AccountType::Checking));

  REQUIRE(p.in_the_red());
  REQUIRE_FALSE(p.in_the_green());
}

TEST_CASE("Portfolio transfer")
{
  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  Account b("B", 500.0, AccountType::Savings);
  int id_a = a.get_id();
  int id_b = b.get_id();
  p.add_account(a);
  p.add_account(b);

  p.transfer(id_a, id_b, 300.0);

  REQUIRE(p.get_account(id_a)->get_balance() == 700.0);
  REQUIRE(p.get_account(id_b)->get_balance() == 800.0);
  REQUIRE(p.net_worth() == 1500.0);
}

TEST_CASE("Portfolio get_account returns null for missing id")
{
  Portfolio p;

  REQUIRE(p.get_account(999999) == nullptr);
}

TEST_CASE("Portfolio transfer preserves net worth")
{
  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  Account b("B", 500.0, AccountType::Savings);
  Account c("C", -300.0, AccountType::CreditCard);
  int id_a = a.get_id();
  int id_b = b.get_id();
  int id_c = c.get_id();
  p.add_account(a);
  p.add_account(b);
  p.add_account(c);

  double before = p.net_worth();

  p.transfer(id_a, id_b, 200.0);
  p.transfer(id_b, id_c, 100.0);

  REQUIRE(p.net_worth() == before);
}
