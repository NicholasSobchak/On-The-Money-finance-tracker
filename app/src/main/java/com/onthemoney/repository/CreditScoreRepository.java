package com.onthemoney.repository;

import com.onthemoney.entity.CreditScoreEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CreditScoreRepository extends JpaRepository<CreditScoreEntity, Long> {
  Optional<CreditScoreEntity> findTopByOrderByDateDescIdDesc();

  List<CreditScoreEntity> findTop2ByOrderByDateDescIdDesc();
}
