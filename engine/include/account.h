#pragma once

#include "transaction.h"
#include <chrono>
#include <cstdint>
#include <string>
#include <vector>

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
  Account(int id, std::string name, double balance, AccountType type);
  ~Account() = default;

  double getBalance() const noexcept { return m_balance; }
  AccountType getType() const noexcept { return m_type; }
  const std::string &getName() const noexcept { return m_name; }
  int getId() const noexcept { return m_id; }

  static void resetIdCounter() noexcept { s_nextId = 1; }

  Transaction deposit(
      double amount,
      std::string description = "",
      std::chrono::sys_days date =
          std::chrono::floor<std::chrono::days>(std::chrono::system_clock::now()));
  Transaction withdraw(
      double amount,
      std::string description = "",
      std::chrono::sys_days date =
          std::chrono::floor<std::chrono::days>(std::chrono::system_clock::now()));

  const std::vector<Transaction> &getTransactions() const noexcept { return m_transactions; }
  double balanceAt(const std::chrono::system_clock::time_point &tp) const noexcept;

  double totalDeposits() const noexcept;
  double totalWithdrawals() const noexcept;
  double netCashFlow() const noexcept;

private:
  std::string m_name;
  int m_id;
  static int s_nextId;
  double m_initial_balance;
  double m_balance;
  AccountType m_type;
  std::vector<Transaction> m_transactions;
};
