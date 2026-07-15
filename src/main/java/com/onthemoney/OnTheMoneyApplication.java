package com.onthemoney;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class OnTheMoneyApplication {

  public static void main(String[] args) {
    try {
      Dotenv dotenv = Dotenv.configure().ignoreIfMissing().load();
      dotenv.entries().forEach(entry -> System.setProperty(entry.getKey(), entry.getValue()));
    } catch (Exception ignored) {
    }
    SpringApplication.run(OnTheMoneyApplication.class, args);
  }
}
// End OnTheMoneyApplication
