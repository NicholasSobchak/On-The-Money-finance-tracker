#include "portfolio.h"
#include <iostream>
#include <nlohmann/json.hpp>
#include <sstream>
#include <stdexcept>
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
using json = nlohmann::json;

namespace
{
AccountType accountTypeFromString(const std::string &s)
{
  if (s == "Checking")
  {
    return AccountType::Checking;
  }
  if (s == "Savings")
  {
    return AccountType::Savings;
  }
  if (s == "CreditCard")
  {
    return AccountType::CreditCard;
  }
  if (s == "Investment")
  {
    return AccountType::Investment;
  }
  if (s == "Loan")
  {
    return AccountType::Loan;
  }
  throw std::invalid_argument("unknown account type: " + s);
}

TransactionType transactionFromString(const std::string &s)
{
  if (s == "Deposit")
  {
    return TransactionType::Deposit;
  }
  if (s == "Withdraw")
  {
    return TransactionType::Withdraw;
  }
  if (s == "Transfer")
  {
    return TransactionType::Transfer;
  }
  throw std::invalid_argument("unknown account type: " + s);
}

json handleGetNetWorth(Portfolio &portfolio, const json &req)
{
  return {{"netWorth", portfolio.netWorth()}};
}

json handleGetTotalAssests(Portfolio &portfolio, const json &req)
{
  return {{"totalAssets", portfolio.totalAssets()}};
}

json handleTotalLiabilities(Portfolio &portfolio, const json &req)
{
  return {{"totalLiabilities", portfolio.totalLiabilities()}};
}

json handleInTheRed(Portfolio &portfolio, const json &req)
{
  return {{"inTheRed", portfolio.inTheRed()}};
}

json handleInTheGreen(Portfolio &portfolio, const json &req)
{
  return {{"inTheGreen", portfolio.inTheGreen()}};
}

json handleAddAccount(Portfolio &portfolio, const json &req)
{
  portfolio.addAccount(Account(req["name"], req["balance"], accountTypeFromString(req["accType"])));
  return {{"status", "ok"}};
}

json handleGetAccountByName(Portfolio &portfolio, const json &req)
{
  Account *account = portfolio.getAccountByName(req["name"]);
  if (!account)
  {
    return {{"status", "error"}, {"message", "account not found"}};
  }
  return {
      {"status", "ok"},
      {"id", account->getId()},
      {"name", account->getName()},
      {"balance", account->getBalance()},
      {"type", static_cast<int>(account->getType())}};
}

json handleTransfer(Portfolio &portfolio, const json &req)
{
  std::chrono::sys_days date =
      req.contains("date")
          ? std::chrono::sys_days{std::chrono::days{req["date"].get<int>()}}
          : std::chrono::floor<std::chrono::days>(std::chrono::system_clock::now());
  Transaction t =
      portfolio.transfer(req["from_account_id"], req["to_account_id"], req["amount"], date);
  return {
      {"status", "ok"},
      {"id", t.getFromAccountId()},
      {"amount", t.getAmount()},
      {"type", static_cast<int>(t.getType())},
      {"date", static_cast<int>(t.getDate().time_since_epoch().count())}};
}

json handleGetAccount(Portfolio &portfolio, const json &req)
{
  Account *account = portfolio.getAccount(req["id"]);
  if (!account)
  {
    return {{"status", "error"}, {"message", "account not found"}};
  }
  return {
      {"status", "ok"},
      {"id", account->getId()},
      {"name", account->getName()},
      {"balance", account->getBalance()},
      {"type", static_cast<int>(account->getType())}};
}

json handleGetTransactions(Portfolio &portfolio, const json &req)
{
  auto start = std::chrono::sys_days{std::chrono::days{req["start"].get<int>()}};
  auto end = std::chrono::sys_days{std::chrono::days{req["end"].get<int>()}};
  auto transactions = portfolio.getTransactions(start, end);

  json arr = json::array();
  for (const auto *t : transactions)
  {
    json obj = {
        {"from_account_id", t->getFromAccountId()},
        {"amount", t->getAmount()},
        {"type", static_cast<int>(t->getType())},
        {"description", t->getDescription()},
        {"date", static_cast<int>(t->getDate().time_since_epoch().count())}};
    if (t->getToAccountId().has_value())
    {
      obj["to_account_id"] = t->getToAccountId().value();
    }
    arr.push_back(obj);
  }
  return {{"status", "ok"}, {"transactions", arr}};
}

json handleNetWorthAt(Portfolio &portfolio, const json &req)
{
  auto date = std::chrono::sys_days{std::chrono::days{req["date"].get<int>()}};
  return {{"netWorth", portfolio.netWorthAt(date)}};
}
} // end namespace

int main()
{
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);

  Portfolio portfolio;
  std::string line;

  while (std::getline(std::cin, line))
  {
    auto req = json::parse(line);
    // then call handler based on req["action"]
    break;
  }

  return 0;
}
