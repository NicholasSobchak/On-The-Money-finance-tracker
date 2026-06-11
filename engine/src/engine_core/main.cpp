#include "portfolio.h"
#include <iostream>
#include <nlohmann/json.hpp>
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
using json = nlohmann::json;

namespace
{
json handleGetNetWorth(Portfolio &portfolio, const json &req)
{
  return {{"netWorth", portfolio.netWorth()}};
}

json handleGetTotalAssests(Portfolio &portfolio, const json &req)
{
  return {{"totalAssets", portfolio.totalAssets()}};
}

// TODO: continue handlers for getters

json handleAddAccount(Portfolio &portfolio, const json &req)
{
  portfolio.addAccount(Account(req["name"], req["balance"], req["accType"]));
  return {{"status", "ok"}};
}

} // end namespace
int main()
{
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);

  Portfolio portfolio;
  std::string line;

  return 0;
}
