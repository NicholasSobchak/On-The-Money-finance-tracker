package com.onthemoney.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

@ExtendWith(MockitoExtension.class)
class EncryptionServiceTest {

  @Mock private JdbcTemplate jdbcTemplate;

  private EncryptionService encryptionService;

  @BeforeEach
  void setUp() {
    encryptionService = new EncryptionService(jdbcTemplate, "test-key-1234567890");
  }

  @Test
  void encrypt_returnsEncryptedValue() {
    when(jdbcTemplate.queryForObject(
            eq("SELECT pgp_sym_encrypt(?, ?)"), eq(String.class), any(), any()))
        .thenReturn("encrypted-data");

    String result = encryptionService.encrypt("plain-text");

    assertEquals("encrypted-data", result);
    verify(jdbcTemplate)
        .queryForObject(
            "SELECT pgp_sym_encrypt(?, ?)", String.class, "plain-text", "test-key-1234567890");
  }

  @Test
  void encrypt_withNull_returnsNull() {
    assertNull(encryptionService.encrypt(null));
  }

  @Test
  void encrypt_withEmpty_returnsEmpty() {
    assertEquals("", encryptionService.encrypt(""));
  }

  @Test
  void encrypt_withoutKey_throwsException() {
    EncryptionService noKeyService = new EncryptionService(jdbcTemplate, "");

    assertThrows(IllegalStateException.class, () -> noKeyService.encrypt("data"));
  }

  @Test
  void encrypt_withNullKey_throwsException() {
    EncryptionService noKeyService = new EncryptionService(jdbcTemplate, null);

    assertThrows(IllegalStateException.class, () -> noKeyService.encrypt("data"));
  }

  @Test
  void decrypt_returnsDecryptedValue() {
    when(jdbcTemplate.queryForObject(
            eq("SELECT pgp_sym_decrypt(?::bytea, ?)"), eq(String.class), any(), any()))
        .thenReturn("plain-text");

    String result = encryptionService.decrypt("encrypted-data");

    assertEquals("plain-text", result);
  }

  @Test
  void decrypt_withNull_returnsNull() {
    assertNull(encryptionService.decrypt(null));
  }

  @Test
  void decrypt_withEmpty_returnsEmpty() {
    assertEquals("", encryptionService.decrypt(""));
  }

  @Test
  void decrypt_withoutKey_throwsException() {
    EncryptionService noKeyService = new EncryptionService(jdbcTemplate, "");

    assertThrows(IllegalStateException.class, () -> noKeyService.decrypt("data"));
  }

  @Test
  void encryptDecrypt_roundtrip_callsCorrectQueries() {
    when(jdbcTemplate.queryForObject(
            eq("SELECT pgp_sym_encrypt(?, ?)"), eq(String.class), any(), any()))
        .thenReturn("pgp-encrypted-bytes");
    when(jdbcTemplate.queryForObject(
            eq("SELECT pgp_sym_decrypt(?::bytea, ?)"), eq(String.class), any(), any()))
        .thenReturn("original-text");

    String encrypted = encryptionService.encrypt("original-text");
    String decrypted = encryptionService.decrypt(encrypted);

    assertEquals("original-text", decrypted);
  }
}
