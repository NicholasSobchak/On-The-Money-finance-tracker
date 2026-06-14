package com.onthemoney.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.service.PortfolioService;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/api")
public class DashboardController {

  private final PortfolioService portfolioService;
  private final ObjectMapper mapper;

  public DashboardController(PortfolioService portfolioService, ObjectMapper mapper) {
    this.portfolioService = portfolioService;
    this.mapper = mapper;
  }

  @GetMapping("/")
  public String index() {
    return "Greetings from the Dashboard Controller";
  }

  @GetMapping("/status")
  public JsonNode getEngineStatus() {
    var status = mapper.createObjectNode();
    status.put("engineStatus", portfolioService.isRunning() ? "online" : "offline");
    return status;
  }

  @PostMapping("/engine")
  public JsonNode handleEngineAction(@RequestBody JsonNode request) throws IOException {
    if (!request.has("action")) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "missing 'action' field");
      return err;
    }
    return portfolioService.send(request);
  }
}
