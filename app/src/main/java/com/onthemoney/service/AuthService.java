package com.onthemoney.service;

import com.onthemoney.entity.UserEntity;
import com.onthemoney.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final TotpService totpService;
  private final SecretKey jwtKey;

  public AuthService(
      UserRepository userRepository,
      PasswordEncoder passwordEncoder,
      TotpService totpService,
      @Value("${JWT_SECRET:}") String jwtSecret) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.totpService = totpService;
    this.jwtKey =
        (jwtSecret != null && !jwtSecret.isEmpty())
            ? Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8))
            : null;
  }

  public UserEntity createUser(String username, String password) {
    UserEntity user = new UserEntity();
    user.setUsername(username);
    user.setPasswordHash(passwordEncoder.encode(password));
    user.setTotpSecret(totpService.generateSecret());
    user.setTotpEnabled(false);
    return userRepository.save(user);
  }

  public String login(String username, String password, String totpCode) {
    if (jwtKey == null) {
      throw new IllegalStateException("JWT_SECRET is not configured");
    }

    UserEntity user =
        userRepository
            .findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

    if (!passwordEncoder.matches(password, user.getPasswordHash())) {
      throw new IllegalArgumentException("Invalid credentials");
    }

    if (user.isTotpEnabled()) {
      if (totpCode == null || totpCode.isEmpty()) {
        throw new IllegalArgumentException("MFA code required");
      }
      if (!totpService.verifyCode(user.getTotpSecret(), totpCode)) {
        throw new IllegalArgumentException("Invalid MFA code");
      }
    }

    return generateToken(user);
  }

  public String enableTotp(String username, String totpCode) {
    UserEntity user =
        userRepository
            .findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found"));

    if (!totpService.verifyCode(user.getTotpSecret(), totpCode)) {
      throw new IllegalArgumentException("Invalid TOTP code");
    }

    user.setTotpEnabled(true);
    userRepository.save(user);
    return "MFA enabled";
  }

  public Claims validateToken(String token) {
    if (jwtKey == null) {
      return null;
    }
    try {
      return Jwts.parser().verifyWith(jwtKey).build().parseSignedClaims(token).getPayload();
    } catch (JwtException | IllegalArgumentException e) {
      return null;
    }
  }

  private String generateToken(UserEntity user) {
    Date now = new Date();
    Date expiry = new Date(now.getTime() + 86400000);
    return Jwts.builder()
        .subject(user.getUsername())
        .issuedAt(now)
        .expiration(expiry)
        .signWith(jwtKey)
        .compact();
  }
}
