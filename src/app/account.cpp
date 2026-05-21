#include "account.h"

Account::Account(std::string name, double balance, AccountType type)
    : m_name(std::move(name)), m_balance(balance), m_type(type)
{
}
