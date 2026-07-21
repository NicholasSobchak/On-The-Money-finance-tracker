package com.onthemoney.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "plaid_items")
public class PlaidItemEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private long id;

  @Column(nullable = false)
  private String accessToken;

  @Column(nullable = false)
  private String itemId;

  private String institutionName;
  private String institutionId;

  public Long getId() {
    return id;
  }

  public void setId(Long id) {
    this.id = id;
  }

  public String getAccessToken() {
    return accessToken;
  }

  public void setAccessToken(String accessToken) {
    this.accessToken = accessToken;
  }

  public String getItemId() {
    return itemId;
  }

  public void setItemId(String itemId) {
    this.itemId = itemId;
  }

  public String getInstitutionName() {
    return institutionName;
  }

  public void setInstitutionName(String instituationName) {
    this.institutionName = institutionName;
  }

  public String getInstitutionId() {
    return institutionId;
  }

  public void setInstitutionId(String institutionId) {
    this.institutionId = institutionId;
  }
} // END PlaidItemEntity
