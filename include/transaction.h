#pragma once

#include <string>

enum class TransactionType
{
  Deposit,
  Withdraw
};

class Transaction
{
public:
private:
  int m_account;
  int m_amount;
  TransactionType m_type;
};
