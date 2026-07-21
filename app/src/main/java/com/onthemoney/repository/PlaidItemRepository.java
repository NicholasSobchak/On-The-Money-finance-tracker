package com.onthemoney.repository;

import com.onthemoney.entity.PlaidItemEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlaidItemRepository extends JpaRepository<PlaidItemEntity, Long> {
  List<PlaidItemEntity> findByInstitutionName(String institutionName);
}
