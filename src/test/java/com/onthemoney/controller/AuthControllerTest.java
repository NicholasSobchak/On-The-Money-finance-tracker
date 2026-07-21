package com.onthemoney.controller;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.entity.UserEntity;
import com.onthemoney.service.AuthService;
import com.onthemoney.service.TotpService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

  private MockMvc mockMvc;
  private ObjectMapper objectMapper = new ObjectMapper();

  @Mock private AuthService authService;
  @Mock private TotpService totpService;

  @InjectMocks private AuthController authController;

  @BeforeEach
  void setUp() {
    mockMvc = MockMvcBuilders.standaloneSetup(authController).build();
  }

  @Test
  void register_withValidInput_returnsUserWithQrCode() throws Exception {
    UserEntity user = new UserEntity();
    user.setId(1L);
    user.setUsername("testuser");
    user.setTotpSecret("ABC123");

    when(authService.createUser("testuser", "password123")).thenReturn(user);
    when(totpService.getIssuer()).thenReturn("TestIssuer");

    mockMvc
        .perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"password\":\"password123\"}"))
        .andExpect(status().isOk())
        .andExpect(
            jsonPath("$.message")
                .value("User created. Scan QR code with your authenticator app, then enable MFA."))
        .andExpect(jsonPath("$.qrDataUri").isNotEmpty())
        .andExpect(jsonPath("$.secret").value("ABC123"));
  }

  @Test
  void register_withShortPassword_returns400() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"password\":\"short\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void register_withBlankUsername_returns400() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"\",\"password\":\"password123\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void register_withMissingFields_returns400() throws Exception {
    mockMvc
        .perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content("{}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void login_withValidCredentials_returnsToken() throws Exception {
    when(authService.login("testuser", "password123", null)).thenReturn("jwt-token-123");

    mockMvc
        .perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"password\":\"password123\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token").value("jwt-token-123"));
  }

  @Test
  void login_withMfaCode_passesCodeToService() throws Exception {
    when(authService.login("testuser", "password123", "654321")).thenReturn("jwt-token-456");

    mockMvc
        .perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"username\":\"testuser\",\"password\":\"password123\",\"totpCode\":\"654321\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token").value("jwt-token-456"));
  }

  @Test
  void login_withInvalidCredentials_returns401() throws Exception {
    when(authService.login("testuser", "wrongpassword", null))
        .thenThrow(new IllegalArgumentException("Invalid credentials"));

    mockMvc
        .perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"password\":\"wrongpassword\"}"))
        .andExpect(status().isUnauthorized());
  }

  @Test
  void login_withMissingPassword_returns400() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void enableMfa_withValidCode_returns200() throws Exception {
    when(authService.enableTotp("testuser", "123456")).thenReturn("MFA enabled");

    mockMvc
        .perform(
            post("/api/auth/mfa/enable")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"totpCode\":\"123456\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message").value("MFA enabled successfully"));
  }

  @Test
  void enableMfa_withInvalidCode_returns401() throws Exception {
    when(authService.enableTotp("testuser", "000000"))
        .thenThrow(new IllegalArgumentException("Invalid TOTP code"));

    mockMvc
        .perform(
            post("/api/auth/mfa/enable")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\",\"totpCode\":\"000000\"}"))
        .andExpect(status().isUnauthorized());
  }

  @Test
  void enableMfa_withMissingFields_returns400() throws Exception {
    mockMvc
        .perform(post("/api/auth/mfa/enable").contentType(MediaType.APPLICATION_JSON).content("{}"))
        .andExpect(status().isBadRequest());
  }
}
