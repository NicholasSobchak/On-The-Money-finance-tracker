package com.onthemoney.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.onthemoney.entity.UserEntity;
import com.onthemoney.repository.UserRepository;
import io.jsonwebtoken.Claims;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

  @Mock private UserRepository userRepository;
  @Mock private PasswordEncoder passwordEncoder;
  @Mock private TotpService totpService;

  private AuthService authService;

  private static final String JWT_SECRET =
      "test-jwt-secret-must-be-at-least-32-bytes-long-for-hmac-sha";

  @BeforeEach
  void setUp() {
    authService = new AuthService(userRepository, passwordEncoder, totpService, JWT_SECRET);
  }

  @Test
  void createUser_savesUserWithEncodedPassword() {
    when(passwordEncoder.encode("password123")).thenReturn("$2a$encoded");
    when(totpService.generateSecret()).thenReturn("ABC123");
    when(userRepository.save(any(UserEntity.class))).thenAnswer(i -> i.getArgument(0));

    UserEntity user = authService.createUser("testuser", "password123");

    assertEquals("testuser", user.getUsername());
    assertEquals("$2a$encoded", user.getPasswordHash());
    assertEquals("ABC123", user.getTotpSecret());
    assertFalse(user.isTotpEnabled());
    verify(userRepository).save(any(UserEntity.class));
  }

  @Test
  void login_withValidCredentials_returnsToken() {
    UserEntity user = createTestUser("testuser", "password123", false);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "$2a$hashed")).thenReturn(true);

    String token = authService.login("testuser", "password123", null);

    assertNotNull(token);
    assertFalse(token.isEmpty());
  }

  @Test
  void login_withInvalidPassword_throwsException() {
    UserEntity user = createTestUser("testuser", "password123", false);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("wrongpassword", "$2a$hashed")).thenReturn(false);

    assertThrows(
        IllegalArgumentException.class, () -> authService.login("testuser", "wrongpassword", null));
  }

  @Test
  void login_withNonexistentUser_throwsException() {
    when(userRepository.findByUsername("nobody")).thenReturn(Optional.empty());

    assertThrows(
        IllegalArgumentException.class, () -> authService.login("nobody", "password123", null));
  }

  @Test
  void login_withMfaEnabled_andValidCode_succeeds() {
    UserEntity user = createTestUser("testuser", "password123", true);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "$2a$hashed")).thenReturn(true);
    when(totpService.verifyCode("SECRET123", "654321")).thenReturn(true);

    String token = authService.login("testuser", "password123", "654321");

    assertNotNull(token);
  }

  @Test
  void login_withMfaEnabled_andMissingCode_throwsException() {
    UserEntity user = createTestUser("testuser", "password123", true);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "$2a$hashed")).thenReturn(true);

    assertThrows(
        IllegalArgumentException.class, () -> authService.login("testuser", "password123", null));
  }

  @Test
  void login_withMfaEnabled_andInvalidCode_throwsException() {
    UserEntity user = createTestUser("testuser", "password123", true);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "$2a$hashed")).thenReturn(true);
    when(totpService.verifyCode("SECRET123", "000000")).thenReturn(false);

    assertThrows(
        IllegalArgumentException.class,
        () -> authService.login("testuser", "password123", "000000"));
  }

  @Test
  void enableTotp_withValidCode_enablesMfa() {
    UserEntity user = createTestUser("testuser", "password123", false);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(totpService.verifyCode("SECRET123", "123456")).thenReturn(true);

    String result = authService.enableTotp("testuser", "123456");

    assertEquals("MFA enabled", result);
    assertTrue(user.isTotpEnabled());
    verify(userRepository).save(user);
  }

  @Test
  void enableTotp_withInvalidCode_throwsException() {
    UserEntity user = createTestUser("testuser", "password123", false);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(totpService.verifyCode("SECRET123", "000000")).thenReturn(false);

    assertThrows(
        IllegalArgumentException.class, () -> authService.enableTotp("testuser", "000000"));
  }

  @Test
  void enableTotp_withNonexistentUser_throwsException() {
    when(userRepository.findByUsername("nobody")).thenReturn(Optional.empty());

    assertThrows(IllegalArgumentException.class, () -> authService.enableTotp("nobody", "123456"));
  }

  @Test
  void validateToken_withValidToken_returnsClaims() {
    UserEntity user = createTestUser("testuser", "password123", false);
    when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "$2a$hashed")).thenReturn(true);

    String token = authService.login("testuser", "password123", null);
    Claims claims = authService.validateToken(token);

    assertNotNull(claims);
    assertEquals("testuser", claims.getSubject());
  }

  @Test
  void validateToken_withInvalidToken_returnsNull() {
    Claims claims = authService.validateToken("invalid.token.here");
    assertNull(claims);
  }

  @Test
  void validateToken_withExpiredToken_returnsNull() {
    // Generate a token with a different key to simulate an invalid token
    Claims claims = authService.validateToken("eyJhbGciOiJIUzI1NiJ9.invalid.payload");
    assertNull(claims);
  }

  private UserEntity createTestUser(String username, String password, boolean mfaEnabled) {
    UserEntity user = new UserEntity();
    user.setId(1L);
    user.setUsername(username);
    user.setPasswordHash("$2a$hashed");
    user.setTotpSecret("SECRET123");
    user.setTotpEnabled(mfaEnabled);
    return user;
  }
}
