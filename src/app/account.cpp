#include "account.h"

int Account::s_nextId{1};

Account::Account(std::string name, double balance, AccountType type)
    : m_id(s_nextId++), m_name(std::move(name)), m_balance(balance), m_type(type)
{
}

Transaction Account::deposit(double amount, std::string description)
{
  m_balance += amount;
  if (description.empty())
  {
    description = m_name + " deposit";
  }
  return Transaction(TransactionType::Deposit, amount, std::move(description), m_id);
}

Transaction Account::withdraw(double amount, std::string description)
{
  m_balance -= amount;
  if (description.empty())
  {
    description = m_name + " withdrawal";
  }
  return Transaction(TransactionType::Withdraw, amount, std::move(description), m_id);
}