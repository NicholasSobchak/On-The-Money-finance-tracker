#include "portfolio.h"

#include <stdexcept>

double Portfolio::net_worth() const noexcept { return total_assets() + total_liabilities(); }

double Portfolio::total_assets() const noexcept
{
  double total{0.0};
  for (const auto &a : m_accounts)
  {
    if (a->get_balance() > 0.0)
    {
      total += a->get_balance();
    }
  }
  return total;
}

double Portfolio::total_liabilities() const noexcept
{
  double total{0.0};
  for (const auto &a : m_accounts)
  {
    if (a->get_balance() < 0.0)
    {
      total += a->get_balance();
    }
  }
  return total; // negative sum
}

bool Portfolio::in_the_red() const noexcept { return net_worth() < 0.0; }

bool Portfolio::in_the_green() const noexcept { return net_worth() >= 0.0; }

void Portfolio::add_account(const Account &account)
{
  m_accounts.push_back(std::make_unique<Account>(account));
}

Transaction Portfolio::transfer(int from_account_id, int to_account_id, double amount)
{
  Account *from{nullptr};
  Account *to{nullptr};

  for (const auto &a : m_accounts)
  {
    if (a->get_id() == from_account_id)
    {
      from = a.get();
    }
    if (a->get_id() == to_account_id)
    {
      to = a.get();
    }
  }

  if (!from)
  {
    throw std::invalid_argument("from_account_id not found");
  }
  if (!to)
  {
    throw std::invalid_argument("to_account_id not found");
  }

  from->withdraw(amount, "Transfer to " + to->get_name());
  to->deposit(amount, "Transfer from " + from->get_name());

  return Transaction(
      TransactionType::Transfer, amount,
      "Transfer from " + from->get_name() + " to " + to->get_name(), from_account_id,
      to_account_id);
}

const Account *Portfolio::get_account(int id) const noexcept
{
  for (const auto &a : m_accounts)
  {
    if (a->get_id() == id)
    {
      return a.get();
    }
  }
  return nullptr;
}
