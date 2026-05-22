#include "portfolio.h"
#include <iostream>

int main()
{
  Portfolio portfolio;
  portfolio.add_account(Account("Nick's savings", 4050.0, AccountType::Savings));
  portfolio.add_account(Account("Nick's checking", 77.0, AccountType::Checking));

  const Account *savings = portfolio.get_account(1);
  const Account *checking = portfolio.get_account(2);

  std::cout << savings->get_name() << " balance: " << savings->get_balance() << '\n';
  std::cout << checking->get_name() << " balance: " << checking->get_balance() << '\n';

  portfolio.transfer(savings->get_id(), checking->get_id(), 100.0);
  std::cout << "Transferring...\n";
  std::cout << savings->get_name() << " new balance: " << savings->get_balance() << '\n';
  std::cout << checking->get_name() << " new balance: " << checking->get_balance() << '\n';

  return 0;
}
