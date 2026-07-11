package com.onthemoney; // package declaration

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class OnTheMoneyApplication {

  public static void main(String[] args) {
    SpringApplication.run(OnTheMoneyApplication.class, args); // starts the Spring app
  }
}
// End OnTheMoneyApplication
