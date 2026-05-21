#include "portfolio.h"

double Portfolio::net_worth() const noexcept { return total_assets() - total_liabilities(); }

double Portfolio::total_assets() const noexcept
{
  double total{0.0};
  for (const auto &a : m_accounts)
  {
    if (a->getBalance() > 0.0)
    {
      total += a->getBalance();
    }
  }
  return total;
}

double Portfolio::total_liabilities() const noexcept
{
  double total{0.0};
  for (const auto &a : m_accounts)
  {
    if (a->getBalance() < 0.0)
    {
      total += a->getBalance();
    }
  }
  return total; // negative sum
}

bool Portfolio::in_the_red() const noexcept { return net_worth() < 0.0; }

bool Portfolio::in_the_green() const noexcept { return net_worth() >= 0.0; }

void Portfolio::add_account(std::unique_ptr<Account> account)
{
  m_accounts.push_back(std::move(account));
}
