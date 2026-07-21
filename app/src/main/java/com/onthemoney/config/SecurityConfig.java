package com.onthemoney.config;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.security.MessageDigest;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Value("${API_KEY:}")
  private String apiKey;

  @Bean
  public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtAuthFilter)
      throws Exception {
    http.csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(
            auth ->
                auth.requestMatchers(
                        "/api/auth/login", "/api/auth/register", "/api/status", "/", "/error")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .addFilterBefore(apiKeyFilter(), UsernamePasswordAuthenticationFilter.class)
        .addFilterAfter(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
  }

  @Bean
  public Filter apiKeyFilter() {
    return new Filter() {
      @Override
      public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
          throws IOException, ServletException {
        if (apiKey == null || apiKey.isEmpty()) {
          HttpServletResponse response = (HttpServletResponse) res;
          response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
          response.setContentType("application/json");
          response
              .getWriter()
              .write(
                  "{\"error\":\"Service Unavailable\",\"message\":\"Server configuration error\"}");
          return;
        }
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        String path = request.getRequestURI();
        if (path.equals("/api/status") || path.equals("/") || path.startsWith("/api/auth")) {
          chain.doFilter(req, res);
          return;
        }

        String provided = request.getHeader("X-API-Key");
        if (provided != null && MessageDigest.isEqual(apiKey.getBytes(), provided.getBytes())) {
          SecurityContextHolder.getContext()
              .setAuthentication(
                  new UsernamePasswordAuthenticationToken(
                      "api-client", null, List.of(new SimpleGrantedAuthority("USER"))));
          chain.doFilter(req, res);
        } else {
          chain.doFilter(req, res);
        }
      }
    };
  }
}
