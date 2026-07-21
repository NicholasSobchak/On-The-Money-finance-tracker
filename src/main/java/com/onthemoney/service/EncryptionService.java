package com.onthemoney.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class EncryptionService {

  private final JdbcTemplate jdbc;
  private final String encryptionKey;

  public EncryptionService(JdbcTemplate jdbc, @Value("${ENCRYPTION_KEY:}") String encryptionKey) {
    this.jdbc = jdbc;
    this.encryptionKey = encryptionKey;
  }

  public String encrypt(String plaintext) {
    if (plaintext == null || plaintext.isEmpty()) {
      return plaintext;
    }
    if (encryptionKey == null || encryptionKey.isEmpty()) {
      throw new IllegalStateException("ENCRYPTION_KEY is not configured");
    }
    return jdbc.queryForObject(
        "SELECT pgp_sym_encrypt(?, ?)", String.class, plaintext, encryptionKey);
  }

  public String decrypt(String ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty()) {
      return ciphertext;
    }
    if (encryptionKey == null || encryptionKey.isEmpty()) {
      throw new IllegalStateException("ENCRYPTION_KEY is not configured");
    }
    return jdbc.queryForObject(
        "SELECT pgp_sym_decrypt(?::bytea, ?)", String.class, ciphertext, encryptionKey);
  }
}
