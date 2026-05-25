#include "transaction.h"

Transaction::Transaction(
    TransactionType type,
    double amount,
    std::string description,
    int from_account_id,
    std::optional<int> to_account_id,
    std::chrono::sys_days date)
    : m_type(type), m_amount(amount), m_description(std::move(description)),
      m_from_account_id(from_account_id), m_to_account_id(to_account_id),
      m_date(date)
{
}

TransactionType Transaction::getType() const noexcept { return m_type; }

double Transaction::getAmount() const noexcept { return m_amount; }

const std::string &Transaction::getDescription() const noexcept { return m_description; }

int Transaction::getFromAccountId() const noexcept { return m_from_account_id; }

std::optional<int> Transaction::getToAccountId() const noexcept { return m_to_account_id; }

std::chrono::sys_days Transaction::getDate() const noexcept { return m_date; }
