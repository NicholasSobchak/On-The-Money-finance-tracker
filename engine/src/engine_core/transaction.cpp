#include "transaction.h"

Transaction::Transaction(
    TransactionType type,
    double amount,
    std::string description,
    int from_account_id,
    std::optional<int> to_account_id)
    : m_type(type), m_amount(amount), m_description(std::move(description)),
      m_from_account_id(from_account_id), m_to_account_id(to_account_id),
      m_date(std::chrono::system_clock::now())
{
}

TransactionType Transaction::get_type() const noexcept { return m_type; }

double Transaction::get_amount() const noexcept { return m_amount; }

const std::string &Transaction::get_description() const noexcept { return m_description; }

int Transaction::get_from_account_id() const noexcept { return m_from_account_id; }

std::optional<int> Transaction::get_to_account_id() const noexcept { return m_to_account_id; }

std::chrono::system_clock::time_point Transaction::get_date() const noexcept { return m_date; }
