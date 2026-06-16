#pragma once

#include "account.h"
#include <chrono>
#include <memory>
#include <vector>

struct BalanceSnapshot
{
  std::chrono::sys_days timestamp;
  double net_worth;
};

class Portfolio
{
public:
  double netWorth() const noexcept;
  double totalAssets() const noexcept;
  double totalLiabilities() const noexcept;
  bool inTheRed() const noexcept;
  bool inTheGreen() const noexcept;

  void addAccount(const Account &account);
  void clear() noexcept;
  Account *getAccountByName(const std::string &name) noexcept;
  Transaction transfer(
      int from_account_id,
      int to_account_id,
      double amount,
      std::chrono::sys_days date =
          std::chrono::floor<std::chrono::days>(std::chrono::system_clock::now()));
  const Account *getAccount(int id) const noexcept;
  Account *getAccount(int id) noexcept;

  double netWorthAt(const std::chrono::system_clock::time_point &tp) const noexcept;
  std::vector<BalanceSnapshot> netWorthSnapshots(
      std::chrono::sys_days start, std::chrono::sys_days end, std::chrono::days interval) const;

  std::vector<const Transaction *> getTransactions(
      const std::chrono::system_clock::time_point &start,
      const std::chrono::system_clock::time_point &end) const;

private:
  std::vector<std::unique_ptr<Account>> m_accounts;
};
