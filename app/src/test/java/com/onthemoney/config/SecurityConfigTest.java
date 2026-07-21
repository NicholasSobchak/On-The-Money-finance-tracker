package com.onthemoney.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityConfigTest {

  @Autowired private MockMvc mockMvc;

  @Test
  void apiStatusEndpoint_returns200WithoutAuth() throws Exception {
    mockMvc.perform(get("/api/status")).andExpect(status().isOk());
  }

  @Test
  void protectedEndpoint_withoutApiKey_returns403() throws Exception {
    mockMvc.perform(get("/api/accounts")).andExpect(status().isForbidden());
  }

  @Test
  void protectedEndpoint_withCorrectApiKey_returns200() throws Exception {
    mockMvc.perform(get("/api/accounts").header("X-API-Key", "test")).andExpect(status().isOk());
  }

  @Test
  void protectedEndpoint_withWrongApiKey_returns403() throws Exception {
    mockMvc
        .perform(get("/api/accounts").header("X-API-Key", "wrong-key"))
        .andExpect(status().isForbidden());
  }

  @Test
  void authLoginEndpoint_doesNotRequireApiKey() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"nobody\",\"password\":\"wrong\"}"))
        .andExpect(status().isUnauthorized());
  }

  @Test
  void authRegisterEndpoint_doesNotRequireApiKey() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"\",\"password\":\"short\"}"))
        .andExpect(status().isBadRequest());
  }
}
