#include "portfolio.h"
#include <iostream>
#include <sstream>
#include <string>

/*
 * OK, so i chose to go with a subprocess through C++ for a couple of reasons.
 *  1. this is a pretty small program in relation to larger ones
 *  2. JNI is a headache to deal with for such a small program
 *  3. Debugging will be much quicker and easier to dael with to complete this project
 *  within a reasonable amount of time
 *  4. As much as I would like to learn and get familiar with JNI in this project,
 *  it is not worth the time when it won't even serve it's purpose (high-performance)
 *  5. I am going with the subprocess
 */

int main()
{
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);

  Portfolio portfolio;
  std::string line;

  // read data via CSV
  while (std::getline(std::cin, line))
  {
    if (line == "END" || line.empty())
    {
      break;
    }

    std::stringstream ss(line);
    std::string accountName, typeStr, amountStr, description;

    // Parse CSV tokens: ACCOUNT_NAME,TYPE,AMOUNT,DESCRIPTION
    if (std::getline(ss, accountName, ',') && std::getline(ss, typeStr, ',') &&
        std::getline(ss, amountStr, ',') && std::getline(ss, description))
    {
      try
      {
        double amount = std::stod(amountStr);

        // Map the text token to your C++ TransactionType enum
        TransactionType type =
            (typeStr == "Deposit") ? TransactionType::Deposit : TransactionType::Withdraw;

        // Push directly into your existing C++ object architecture
        Account *account = portfolio.getAccountByName(accountName);
        if (!account)
        {
          portfolio.addAccount(Account(accountName, 0.0, AccountType::Checking));
          account = portfolio.getAccountByName(accountName);
        }

        if (type == TransactionType::Deposit)
        {
          account->deposit(amount, description);
        }
        else
        {
          account->withdraw(amount, description);
        }
      }
      catch (const std::invalid_argument &e)
      {
        // Ignore malformed numeric strings to prevent engine crashes
        continue;
      }
    }
  }

  // Output the final calculation down the stdout pipe for Java to catch
  std::cout << portfolio.netWorth() << "\n";

  return 0;
}
