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
  REQUIRE(p.net_worth() == 1700.0);
  REQUIRE(p.in_the_green());
  REQUIRE_FALSE(p.in_the_red());
}
