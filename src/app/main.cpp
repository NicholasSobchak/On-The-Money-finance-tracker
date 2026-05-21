#include "portfolio.h"
#include <iostream>

int main()
{
  Account savings("Nick's savings", 4050.0, AccountType::Savings);
  Account checking("Nick's checkings", 77.0, AccountType::Checking);
  Portfolio portfolio;
  portfolio.add_account(savings);
  portfolio.add_account(checking);

  std::cout << "Nick's net worth is: $" << portfolio.net_worth() << '\n';

  return 0;
}
