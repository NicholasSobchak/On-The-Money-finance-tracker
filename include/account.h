#pragma once

#include "transaction.h"
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

  double get_balance() const noexcept { return m_balance; }
  AccountType get_type() const noexcept { return m_type; }
  const std::string &get_name() const noexcept { return m_name; }
  int get_id() const noexcept { return m_id; }

  Transaction deposit(double amount, std::string description = "");
  Transaction withdraw(double amount, std::string description = "");

private:
  std::string m_name;
  int m_id;
  static int s_nextId;
  double m_balance;
  AccountType m_type;
};
