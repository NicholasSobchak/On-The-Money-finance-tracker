/*
 * C++ Engine — Monte Carlo retirement projection
 *
 * This is the heavy-lifting component. For simple portfolio math
 * (net worth, total assets, etc.), Java handles it directly.
 * This engine is only used for computations that benefit from
 * C++ speed — like running 10,000+ market simulations.
 *
 * Protocol: newline-delimited JSON over stdin/stdout.
 *   Request:  {"action":"projectRetirement", "initialBalance":..., ...}
 *   Response: {"median":..., "worst10":..., "best10":..., "percentiles":[...]}
 */

#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <nlohmann/json.hpp>
#include <random>
#include <vector>

using json = nlohmann::json;

namespace
{

double monteCarloPercentile(std::vector<double> &results, double p)
{
  if (results.empty())
  {
    return 0.0;
  }
  size_t idx = static_cast<size_t>(std::round(p / 100.0 * (results.size() - 1)));
  return results[idx];
}

json handleProjectRetirement(const json &req)
{
  double initialBalance = req["initialBalance"].get<double>();
  double monthlyContribution = req["monthlyContribution"].get<double>();
  double returnRate = req["returnRate"].get<double>(); // e.g. 0.07 for 7%
  int years = req["years"].get<int>();
  int simulations = req["simulations"].get<int>();

  double annualContribution = monthlyContribution * 12;
  double volatility = 0.10; // ~10% annual std dev for stock market

  std::mt19937_64 rng(std::random_device{}());
  std::normal_distribution<double> noise(0.0, volatility);

  std::vector<double> results;
  results.reserve(simulations);

  for (int s = 0; s < simulations; ++s)
  {
    double balance = initialBalance;
    for (int y = 0; y < years; ++y)
    {
      double annualReturn = returnRate + noise(rng);
      balance = balance * (1.0 + annualReturn) + annualContribution;
    }
    results.push_back(balance);
  }

  std::sort(results.begin(), results.end());

  // return number of results sorted, statistics
  auto worst10 = results[static_cast<size_t>(simulations * 0.10)];
  auto median = results[static_cast<size_t>(simulations * 0.50)];
  auto best10 = results[static_cast<size_t>(simulations * 0.90)];
  auto mean = std::accumulate(results.begin(), results.end(), 0.0) / simulations;

  json percentiles = json::array();
  for (double p = 5.0; p <= 95.0; p += 5.0)
  {
    percentiles.push_back(monteCarloPercentile(results, p));
  }

  return {
      {"status", "ok"},
      {"worst10", worst10},
      {"median", median},
      {"best10", best10},
      {"mean", mean},
      {"simulations", simulations},
      {"percentiles", percentiles},
  };
}

} // namespace

int main()
{
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);

  std::string line;
  while (std::getline(std::cin, line))
  {
    try
    {
      auto req = json::parse(line);
      auto action = req["action"].get<std::string>();

      if (action == "projectRetirement")
      {
        std::cout << handleProjectRetirement(req).dump() << "\n" << std::flush;
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
