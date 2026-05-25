#include "account.h"

int Account::s_nextId{1};

Account::Account(std::string name, double balance, AccountType type)
    : m_id(s_nextId++), m_name(std::move(name)), m_initial_balance(balance), m_balance(balance), m_type(type)
{
}

Transaction Account::deposit(double amount, std::string description, std::chrono::sys_days date)
{
  m_balance += amount;
  if (description.empty())
  {
    description = m_name + " deposit";
  }
  Transaction t(TransactionType::Deposit, amount, description, m_id, std::nullopt, date);
  m_transactions.push_back(t);
  return t;
}

Transaction Account::withdraw(double amount, std::string description, std::chrono::sys_days date)
{
  m_balance -= amount;
  if (description.empty())
  {
    description = m_name + " withdrawal";
  }
  Transaction t(TransactionType::Withdraw, amount, description, m_id, std::nullopt, date);
  m_transactions.push_back(t);
  return t;
}

double Account::balanceAt(const std::chrono::system_clock::time_point &tp) const noexcept
{
  double balance = m_initial_balance;
  for (const auto &t : m_transactions)
  {
    if (t.getDate() > tp)
    {
      continue;
    }
    if (t.getType() == TransactionType::Deposit)
    {
      balance += t.getAmount();
    }
    else
    {
      balance -= t.getAmount();
    }
  }
  return balance;
}

double Account::totalDeposits() const noexcept
{
  double total = 0.0;
  for (const auto &t : m_transactions)
  {
    if (t.getType() == TransactionType::Deposit)
    {
      total += t.getAmount();
    }
  }
  return total;
}

double Account::totalWithdrawals() const noexcept
{
  double total = 0.0;
  for (const auto &t : m_transactions)
  {
    if (t.getType() == TransactionType::Withdraw)
    {
      total += t.getAmount();
    }
  }
  return total;
}

double Account::netCashFlow() const noexcept
{
  return totalDeposits() - totalWithdrawals();
}