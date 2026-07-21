package com.onthemoney.service;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TotpServiceTest {

  private TotpService totpService;

  @BeforeEach
  void setUp() {
    totpService = new TotpService();
    // Use reflection to set the issuer field since it's @Value-injected
    try {
      var field = TotpService.class.getDeclaredField("issuer");
      field.setAccessible(true);
      field.set(totpService, "TestIssuer");
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Test
  void generateSecret_returnsNonEmptyString() {
    String secret = totpService.generateSecret();
    assertNotNull(secret);
    assertFalse(secret.isEmpty());
  }

  @Test
  void generateSecret_returnsDifferentValues() {
    String secret1 = totpService.generateSecret();
    String secret2 = totpService.generateSecret();
    assertNotEquals(secret1, secret2);
  }

  @Test
  void getIssuer_returnsConfiguredValue() {
    assertEquals("TestIssuer", totpService.getIssuer());
  }

  @Test
  void verifyCode_rejectsInvalidCode() {
    String secret = totpService.generateSecret();
    assertFalse(totpService.verifyCode(secret, "000000"));
  }

  @Test
  void verifyCode_withNullSecret_returnsFalse() {
    assertFalse(totpService.verifyCode(null, "123456"));
  }
}
