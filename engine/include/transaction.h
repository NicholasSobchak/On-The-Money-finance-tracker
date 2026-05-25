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
      std::optional<int> to_account_id = std::nullopt,
      std::chrono::sys_days date = std::chrono::floor<std::chrono::days>(std::chrono::system_clock::now()));

  TransactionType getType() const noexcept;
  double getAmount() const noexcept;
  const std::string &getDescription() const noexcept;
  int getFromAccountId() const noexcept;
  std::optional<int> getToAccountId() const noexcept;
  std::chrono::sys_days getDate() const noexcept;

private:
  TransactionType m_type;
  double m_amount;
  std::string m_description;
  int m_from_account_id;
  std::optional<int> m_to_account_id; // only set for transfers
  std::chrono::sys_days m_date;
};
