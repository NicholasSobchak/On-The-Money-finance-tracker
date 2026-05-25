#include "portfolio.h"
#include <iostream>

int main()
{
  Account::resetIdCounter();
  Portfolio portfolio;
  portfolio.addAccount(Account("Nick's savings", 3500.0, AccountType::Savings));
  portfolio.addAccount(Account("Nick's checking", 50.0, AccountType::Checking));

  Account *savings = portfolio.getAccount(1);
  Account *checking = portfolio.getAccount(2);

  auto today = floor<std::chrono::days>(std::chrono::system_clock::now());

  Transaction birthday = savings->deposit(200.0, "Birthday money", today);
  Transaction coffee = checking->withdraw(25.0, "Coffee", today);

  Transaction t = portfolio.transfer(savings->getId(), checking->getId(), 100.0, today);

  std::cout << "=== Account Balances ===\n";
  std::cout << savings->getName() << ": $" << savings->getBalance() << '\n';
  std::cout << checking->getName() << ": $" << checking->getBalance() << '\n';

  std::cout << "\n=== Deposit Info ===\n";
  std::cout << "Description: " << birthday.getDescription() << '\n';
  std::cout << "Amount: $" << birthday.getAmount() << '\n';
  std::cout << "Account ID: " << birthday.getFromAccountId() << '\n';
  std::cout << "Date: " << std::chrono::year_month_day{birthday.getDate()} << '\n';

  std::cout << "\n=== Withdrawal Info ===\n";
  std::cout << "Description: " << coffee.getDescription() << '\n';
  std::cout << "Amount: $" << coffee.getAmount() << '\n';
  std::cout << "Account ID: " << coffee.getFromAccountId() << '\n';
  std::cout << "Date: " << std::chrono::year_month_day{coffee.getDate()} << '\n';

  std::cout << "\n=== Transfer Info ===\n";
  std::cout << "Description: " << t.getDescription() << '\n';
  std::cout << "Amount: $" << t.getAmount() << '\n';
  std::cout << "From account ID: " << t.getFromAccountId() << '\n';
  std::cout << "Date: " << std::chrono::year_month_day{t.getDate()} << '\n';
  if (auto to_id = t.getToAccountId())
  {
    std::cout << "To account ID: " << *to_id << '\n';
  }

  std::cout << "\n=== Savings Transaction History ===\n";
  for (const auto &txn : savings->getTransactions())
  {
    std::cout << "  " << txn.getDescription() << " | $" << txn.getAmount() << " | " << std::chrono::year_month_day{txn.getDate()} << '\n';
  }

  std::cout << "\n=== Checking Transaction History ===\n";
  for (const auto &txn : checking->getTransactions())
  {
    std::cout << "  " << txn.getDescription() << " | $" << txn.getAmount() << " | " << std::chrono::year_month_day{txn.getDate()} << '\n';
  }

  std::cout << "\n=== Summary ===\n";
  std::cout << "Savings total deposits: $" << savings->totalDeposits() << '\n';
  std::cout << "Checking total withdrawals: $" << checking->totalWithdrawals() << '\n';
  std::cout << "Portfolio net worth: $" << portfolio.netWorth() << '\n';

  return 0;
}
