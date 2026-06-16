#include "portfolio.h"
#include <functional>
#include <iostream>
#include <nlohmann/json.hpp>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>

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

void loadAccounts(Portfolio &portfolio, const json &req)
{
  portfolio.clear();
  Account::resetIdCounter();
  for (const auto &a : req["accounts"])
  {
    portfolio.addAccount(Account(a["name"], a["balance"], accountTypeFromString(a["accType"])));
  }
}

json handleGetNetWorth(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  return {{"netWorth", portfolio.netWorth()}};
}

json handleGetTotalAssets(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  return {{"totalAssets", portfolio.totalAssets()}};
}

json handleTotalLiabilities(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  return {{"totalLiabilities", portfolio.totalLiabilities()}};
}

json handleInTheRed(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  return {{"inTheRed", portfolio.inTheRed()}};
}

json handleInTheGreen(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  return {{"inTheGreen", portfolio.inTheGreen()}};
}

json handleNetWorthAt(Portfolio &portfolio, const json &req)
{
  loadAccounts(portfolio, req);
  auto date = std::chrono::sys_days{std::chrono::days{req["date"].get<int>()}};
  return {{"netWorth", portfolio.netWorthAt(std::chrono::system_clock::time_point(date))}};
}
} // namespace

int main()
{
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);

  Portfolio portfolio;

  std::unordered_map<std::string, std::function<json(Portfolio &, const json &)>> handlers = {
      {"getNetWorth", handleGetNetWorth},
      {"getTotalAssets", handleGetTotalAssets},
      {"totalLiabilities", handleTotalLiabilities},
      {"inTheRed", handleInTheRed},
      {"inTheGreen", handleInTheGreen},
      {"netWorthAt", handleNetWorthAt},
  };

  std::string line;
  while (std::getline(std::cin, line))
  {
    try
    {
      auto req = json::parse(line);
      auto action = req["action"].get<std::string>();

      auto it = handlers.find(action);
      if (it != handlers.end())
      {
        std::cout << it->second(portfolio, req).dump() << "\n" << std::flush;
      }
      else
      {
        std::cout << json({{"status", "error"}, {"message", "unknown action: " + action}}).dump()
                  << "\n"
                  << std::flush;
      }
    }
    catch (const std::exception &e)
    {
      try
      {
        std::cout << json({{"status", "error"}, {"message", e.what()}}).dump() << "\n"
                  << std::flush;
      }
      catch (...)
      {
        std::cout << "{\"status\":\"error\",\"message\":\"internal error\"}\n" << std::flush;
      }
    }
  }

  return 0;
}
