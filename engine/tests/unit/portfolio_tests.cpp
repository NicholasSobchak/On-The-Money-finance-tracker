#include <catch2/catch_test_macros.hpp>

#include "portfolio.h"

TEST_CASE("Portfolio net worth")
{
  Portfolio p;

  p.addAccount(Account("Checking", 500.0, AccountType::Checking));
  p.addAccount(Account("Savings", 1000.0, AccountType::Savings));
  p.addAccount(Account("Credit Card", -200.0, AccountType::CreditCard));

  REQUIRE(p.totalAssets() == 1500.0);
  REQUIRE(p.totalLiabilities() == -200.0);
  REQUIRE(p.netWorth() == 1300.0);
  REQUIRE(p.inTheGreen());
  REQUIRE_FALSE(p.inTheRed());
}

TEST_CASE("Portfolio in the red")
{
  Portfolio p;
  p.addAccount(Account("Loan", -5000.0, AccountType::Loan));
  p.addAccount(Account("Checking", 100.0, AccountType::Checking));

  REQUIRE(p.inTheRed());
  REQUIRE_FALSE(p.inTheGreen());
}

TEST_CASE("Portfolio transfer")
{
  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  Account b("B", 500.0, AccountType::Savings);
  int id_a = a.getId();
  int id_b = b.getId();
  p.addAccount(a);
  p.addAccount(b);

  p.transfer(id_a, id_b, 300.0);

  REQUIRE(p.getAccount(id_a)->getBalance() == 700.0);
  REQUIRE(p.getAccount(id_b)->getBalance() == 800.0);
  REQUIRE(p.netWorth() == 1500.0);
}

TEST_CASE("Portfolio get_account returns null for missing id")
{
  Portfolio p;

  REQUIRE(p.getAccount(999999) == nullptr);
}

TEST_CASE("Portfolio transfer preserves net worth")
{
  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  Account b("B", 500.0, AccountType::Savings);
  Account c("C", -300.0, AccountType::CreditCard);
  int id_a = a.getId();
  int id_b = b.getId();
  int id_c = c.getId();
  p.addAccount(a);
  p.addAccount(b);
  p.addAccount(c);

  double before = p.netWorth();

  p.transfer(id_a, id_b, 200.0);
  p.transfer(id_b, id_c, 100.0);

  REQUIRE(p.netWorth() == before);
}

TEST_CASE("Portfolio net_worth_at returns historical net worth")
{
  using namespace std::chrono;
  auto today = floor<days>(system_clock::now());
  auto yesterday = today - days{1};
  auto tomorrow = today + days{1};

  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  Account b("B", 500.0, AccountType::Savings);
  p.addAccount(a);
  p.addAccount(b);

  p.getAccount(a.getId())->deposit(200.0, "", yesterday);
  p.getAccount(a.getId())->withdraw(100.0, "", today);

  REQUIRE(p.netWorthAt(system_clock::time_point(yesterday - days{1})) == 1500.0);
  REQUIRE(p.netWorthAt(system_clock::time_point(yesterday)) == 1700.0);
  REQUIRE(p.netWorthAt(system_clock::time_point(tomorrow)) == 1600.0);
}

TEST_CASE("Portfolio net_worth_snapshots returns snapshots in range")
{
  using namespace std::chrono;
  auto today = floor<days>(system_clock::now());

  Portfolio p;
  p.addAccount(Account("A", 1000.0, AccountType::Checking));
  p.addAccount(Account("B", 500.0, AccountType::Savings));

  auto snapshots = p.netWorthSnapshots(today - days{1}, today + days{1}, days{1});

  REQUIRE(snapshots.size() == 3);
  for (const auto &s : snapshots)
  {
    REQUIRE(s.net_worth == 1500.0);
  }
}

TEST_CASE("Portfolio get_transactions filters by date range")
{
  using namespace std::chrono;
  auto today = floor<days>(system_clock::now());
  auto yesterday = today - days{1};
  auto tomorrow = today + days{1};

  Portfolio p;
  Account a("A", 1000.0, AccountType::Checking);
  int id_a = a.getId();
  p.addAccount(a);

  p.getAccount(id_a)->deposit(200.0, "", yesterday);
  p.getAccount(id_a)->withdraw(100.0, "", today);

  auto all = p.getTransactions(system_clock::time_point(yesterday - days{1}),
                                system_clock::time_point(tomorrow));
  REQUIRE(all.size() == 2);

  auto first_only = p.getTransactions(system_clock::time_point(yesterday - days{1}),
                                      system_clock::time_point(yesterday));
  REQUIRE(first_only.size() == 1);
  REQUIRE(first_only[0]->getAmount() == 200.0);

  auto later_only = p.getTransactions(system_clock::time_point(today),
                                      system_clock::time_point(tomorrow));
  REQUIRE(later_only.size() == 1);
  REQUIRE(later_only[0]->getAmount() == 100.0);
}


