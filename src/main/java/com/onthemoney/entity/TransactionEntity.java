package com.onthemoney.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "transactions")
public class TransactionEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private Long fromAccountId;

  private Long toAccountId;

  private double amount;

  private String description;

  private LocalDate date;

  public static final int TYPE_DEPOSIT = 0;
  public static final int TYPE_WITHDRAW = 1;
  public static final int TYPE_TRANSFER = 2;

  private int type;

  public Long getId() {
    return id;
  }

  public void setId(Long id) {
    this.id = id;
  }

  public Long getFromAccountId() {
    return fromAccountId;
  }

  public void setFromAccountId(Long fromAccountId) {
    this.fromAccountId = fromAccountId;
  }

  public Long getToAccountId() {
    return toAccountId;
  }

  public void setToAccountId(Long toAccountId) {
    this.toAccountId = toAccountId;
  }

  public double getAmount() {
    return amount;
  }

  public void setAmount(double amount) {
    this.amount = amount;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  public LocalDate getDate() {
    return date;
  }

  public void setDate(LocalDate date) {
    this.date = date;
  }

  public int getType() {
    return type;
  }

  public void setType(int type) {
    this.type = type;
  }
}
