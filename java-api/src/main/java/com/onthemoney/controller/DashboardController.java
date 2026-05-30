package com.onthemoney.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestParam;

@RestController("/api")
public class DashboardController {

  @GetMapping("/")
  public String index() {
    return "Greetings from the Dashboard Controller";
  }

  @GetMapping("/status")
  public String getEngineStatus(@RequestParam(defaultValue = "offline") String engine){
    return "{\"engineStatus\": \"" + engine + "\"}";
  }

}
