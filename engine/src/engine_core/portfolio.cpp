#include "portfolio.h"

#include <stdexcept>

double Portfolio::netWorth() const noexcept { return totalAssets() + totalLiabilities(); }

double Portfolio::totalAssets() const noexcept
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

double Portfolio::totalLiabilities() const noexcept
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

bool Portfolio::inTheRed() const noexcept { return netWorth() < 0.0; }

bool Portfolio::inTheGreen() const noexcept { return netWorth() >= 0.0; }

void Portfolio::addAccount(const Account &account)
{
  m_accounts.push_back(std::make_unique<Account>(account));
}

Transaction Portfolio::transfer(
    int from_account_id, int to_account_id, double amount, std::chrono::sys_days date)
{
  Account *from{nullptr};
  Account *to{nullptr};

  for (const auto &a : m_accounts)
  {
    if (a->getId() == from_account_id)
    {
      from = a.get();
    }
    if (a->getId() == to_account_id)
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

  from->withdraw(amount, "Transfer to " + to->getName(), date);
  to->deposit(amount, "Transfer from " + from->getName(), date);

  return Transaction(
      TransactionType::Transfer, amount,
      "Transfer from " + from->getName() + " to " + to->getName(), from_account_id, to_account_id,
      date);
}

const Account *Portfolio::getAccount(int id) const noexcept
{
  for (const auto &a : m_accounts)
  {
    if (a->getId() == id)
    {
      return a.get();
    }
  }
  return nullptr;
}

Account *Portfolio::getAccount(int id) noexcept
{
  for (const auto &a : m_accounts)
  {
    if (a->getId() == id)
    {
      return a.get();
    }
  }
  return nullptr;
}

double Portfolio::netWorthAt(const std::chrono::system_clock::time_point &tp) const noexcept
{
  double total = 0.0;
  for (const auto &a : m_accounts)
  {
    total += a->balanceAt(tp);
  }
  return total;
}

std::vector<BalanceSnapshot> Portfolio::netWorthSnapshots(
    std::chrono::sys_days start, std::chrono::sys_days end, std::chrono::days interval) const
{
  std::vector<BalanceSnapshot> snapshots;
  for (auto t = start; t <= end; t += interval)
  {
    snapshots.push_back({t, netWorthAt(std::chrono::system_clock::time_point(t))});
  }
  return snapshots;
}

std::vector<const Transaction *> Portfolio::getTransactions(
    const std::chrono::system_clock::time_point &start,
    const std::chrono::system_clock::time_point &end) const
{
  std::vector<const Transaction *> result;
  for (const auto &a : m_accounts)
  {
    for (const auto &t : a->getTransactions())
    {
      if (t.getDate() >= start && t.getDate() <= end)
      {
        result.push_back(&t);
      }
    }
  }
  return result;
}
