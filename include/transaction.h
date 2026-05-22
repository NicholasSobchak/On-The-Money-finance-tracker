#pragma once

#include <chrono>
#include <cstdint>
#include <optional>
#include <string>

enum class TransactionType : std::uint8_t
{
  Deposit,
  Withdraw,
  Transfer
};

class Transaction
{
public:
  Transaction(
      TransactionType type,
      double amount,
      std::string description,
      int from_account_id,
      std::optional<int> to_account_id = std::nullopt);

  TransactionType get_type() const noexcept;
  double get_amount() const noexcept;
  const std::string &get_description() const noexcept;
  int get_from_account_id() const noexcept;
  std::optional<int> get_to_account_id() const noexcept;
  std::chrono::system_clock::time_point get_date() const noexcept;

private:
  TransactionType m_type;
  double m_amount;
  std::string m_description;
  int m_from_account_id;
  std::optional<int> m_to_account_id; // only set for transfers
  std::chrono::system_clock::time_point m_date;
};
