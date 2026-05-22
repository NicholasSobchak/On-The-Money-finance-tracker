#pragma once

#include "account.h"
#include <memory>
#include <vector>

class Portfolio
{
public:
  double net_worth() const noexcept;
  double total_assets() const noexcept;
  double total_liabilities() const noexcept;
  bool in_the_red() const noexcept;
  bool in_the_green() const noexcept;

  void add_account(const Account &account);
  Transaction transfer(int from_account_id, int to_account_id, double amount);
  const Account *get_account(int id) const noexcept;

private:
  std::vector<std::unique_ptr<Account>> m_accounts;
};
