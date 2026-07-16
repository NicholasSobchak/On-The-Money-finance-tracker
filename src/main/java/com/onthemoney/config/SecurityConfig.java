package com.onthemoney.config;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Value("${API_KEY:}")
  private String apiKey;

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
        .addFilterBefore(apiKeyFilter(), UsernamePasswordAuthenticationFilter.class);
    return http.build();
  }

  @Bean
  public Filter apiKeyFilter() {
    return new Filter() {
      @Override
      public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
          throws IOException, ServletException {
        if (apiKey == null || apiKey.isEmpty()) {
          chain.doFilter(req, res);
          return;
        }
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        String path = request.getRequestURI();
        if (path.equals("/api/status") || path.equals("/")) {
          chain.doFilter(req, res);
          return;
        }

        String provided = request.getHeader("X-API-Key");
        if (apiKey.equals(provided)) {
          chain.doFilter(req, res);
        } else {
          response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
          response.setContentType("application/json");
          response
              .getWriter()
              .write("{\"error\":\"Unauthorized\",\"message\":\"Missing or invalid API key\"}");
        }
      }
    };
  }
}
