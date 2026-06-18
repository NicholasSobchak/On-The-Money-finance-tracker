package com.onthemoney.repository;

import com.onthemoney.entity.TransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TransactionRepository extends JpaRepository<TransactionEntity, Long> {
  List<TransactionEntity> findByDateBetween(LocalDate start, LocalDate end);
  List<TransactionEntity> findByFromAccountIdOrToAccountId(Long fromAccountId, Long toAccountId);
}
