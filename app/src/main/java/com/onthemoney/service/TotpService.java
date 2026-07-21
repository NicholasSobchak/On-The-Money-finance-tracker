package com.onthemoney.service;

import dev.samstevens.totp.code.DefaultCodeGenerator;
import dev.samstevens.totp.code.DefaultCodeVerifier;
import dev.samstevens.totp.secret.DefaultSecretGenerator;
import dev.samstevens.totp.time.SystemTimeProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class TotpService {

  private final DefaultCodeGenerator codeGenerator = new DefaultCodeGenerator();
  private final DefaultSecretGenerator secretGenerator = new DefaultSecretGenerator();
  private final DefaultCodeVerifier codeVerifier =
      new DefaultCodeVerifier(codeGenerator, new SystemTimeProvider());

  @Value("${TOTP_ISSUER:OnTheMoney}")
  private String issuer;

  public String generateSecret() {
    return secretGenerator.generate();
  }

  public String getIssuer() {
    return issuer;
  }

  public boolean verifyCode(String secret, String code) {
    return codeVerifier.isValidCode(secret, code);
  }
}
