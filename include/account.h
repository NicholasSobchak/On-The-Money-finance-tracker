#pragma once

#include <cstdint>
#include <string>

enum class AccountType : std::uint8_t
{
  Checking,
  Savings,
  CreditCard,
  Investment,
  Loan
};

class Account
{
public:
  Account(std::string name, double balance, AccountType type);
  ~Account() = default;

  double getBalance() const noexcept { return m_balance; }
  AccountType getType() const noexcept { return m_type; }

private:
  std::string m_name;
  double m_balance;
  AccountType m_type;
};
