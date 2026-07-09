package com.onthemoney.repository;

import com.onthemoney.entity.NetWorthHistoryEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NetWorthHistoryRepository extends JpaRepository<NetWorthHistoryEntity, Long> {
  List<NetWorthHistoryEntity> findAllByOrderByDateAsc();
}
