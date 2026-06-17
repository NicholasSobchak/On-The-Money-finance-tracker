#pragma once

#include <nlohmann/json.hpp>
#include <vector>

using json = nlohmann::json;

namespace engine_core
{

double monteCarloPercentile(std::vector<double> &results, double p);

json projectRetirement(
    double initialBalance,
    double monthlyContribution,
    double returnRate,
    int years,
    int simulations);

} // namespace engine_core
