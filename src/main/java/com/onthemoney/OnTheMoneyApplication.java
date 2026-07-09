package com.onthemoney; // package declaration

import org.springframework.boot.SpringApplication; // imports the bootstrap class
import org.springframework.boot.autoconfigure.SpringBootApplication; // imports

// @SpringBootApplication

@SpringBootApplication //
public class OnTheMoneyApplication {

  public static void main(String[] args) {
    SpringApplication.run(OnTheMoneyApplication.class, args); // starts the Spring app
  }
}
// End OnTheMoneyApplication
