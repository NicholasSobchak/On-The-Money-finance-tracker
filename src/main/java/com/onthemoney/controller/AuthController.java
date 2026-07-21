package com.onthemoney.controller;

import com.onthemoney.entity.UserEntity;
import com.onthemoney.service.AuthService;
import com.onthemoney.service.TotpService;
import dev.samstevens.totp.qr.QrData;
import dev.samstevens.totp.qr.ZxingPngQrGenerator;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

  private final AuthService authService;
  private final TotpService totpService;

  public AuthController(AuthService authService, TotpService totpService) {
    this.authService = authService;
    this.totpService = totpService;
  }

  @PostMapping("/register")
  public Map<String, Object> register(@RequestBody Map<String, String> body) throws Exception {
    String username = body.get("username");
    String password = body.get("password");

    if (username == null || username.isBlank() || password == null || password.length() < 8) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "Username and password (min 8 chars) required");
    }

    UserEntity user;
    try {
      user = authService.createUser(username, password);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
    }

    QrData data =
        new QrData.Builder()
            .label(username)
            .secret(user.getTotpSecret())
            .issuer(totpService.getIssuer())
            .algorithm(dev.samstevens.totp.code.HashingAlgorithm.SHA1)
            .digits(6)
            .period(30)
            .build();

    ZxingPngQrGenerator generator = new ZxingPngQrGenerator();
    byte[] imageData = generator.generate(data);
    String mimeType = generator.getImageMimeType();
    String qrDataUri = dev.samstevens.totp.util.Utils.getDataUriForImage(imageData, mimeType);

    return Map.of(
        "message",
        "User created. Scan QR code with your authenticator app, then enable MFA.",
        "qrDataUri",
        qrDataUri,
        "secret",
        user.getTotpSecret());
  }

  @PostMapping("/login")
  public Map<String, String> login(@RequestBody Map<String, String> body) {
    String username = body.get("username");
    String password = body.get("password");
    String totpCode = body.get("totpCode");

    if (username == null || password == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Username and password required");
    }

    String token;
    try {
      token = authService.login(username, password, totpCode);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, e.getMessage());
    }
    return Map.of("token", token);
  }

  @PostMapping("/mfa/enable")
  public Map<String, String> enableMfa(@RequestBody Map<String, String> body) {
    String username = body.get("username");
    String totpCode = body.get("totpCode");

    if (username == null || totpCode == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Username and TOTP code required");
    }

    try {
      authService.enableTotp(username, totpCode);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, e.getMessage());
    }
    return Map.of("message", "MFA enabled successfully");
  }
}
