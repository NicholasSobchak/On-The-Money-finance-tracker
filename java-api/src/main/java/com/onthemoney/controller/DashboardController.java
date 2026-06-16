package com.onthemoney.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.service.PortfolioService;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

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

  @GetMapping("/net-worth")
  public JsonNode getNetWorth() throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "getNetWorth");
    return portfolioService.send(request);
  }

  @GetMapping("/total-assets")
  public JsonNode getTotalAssets() throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "getTotalAssets");
    return portfolioService.send(request);
  }

  @GetMapping("/total-liabilities")
  public JsonNode getTotalLiabilities() throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "totalLiabilities");
    return portfolioService.send(request);
  }

  @GetMapping("/in-the-red")
  public JsonNode getInTheRed() throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "inTheRed");
    return portfolioService.send(request);
  }

  @GetMapping("/in-the-green")
  public JsonNode getInTheGreen() throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "inTheGreen");
    return portfolioService.send(request);
  }

  @PostMapping("/accounts")
  public JsonNode addAccount(@RequestParam String name,
                             @RequestParam double balance,
                             @RequestParam String accType) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "addAccount");
    request.put("name", name);
    request.put("balance", balance);
    request.put("accType", accType);
    return portfolioService.send(request);
  }

  @GetMapping("/accounts")
  public JsonNode getAccountByName(@RequestParam(defaultValue = "all") String name) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "getAccountByName");
    request.put("name", name);
    return portfolioService.send(request);
  }

  @GetMapping("/accounts/{id}")
  public JsonNode getAccountById(@PathVariable int id) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "getAccount");
    request.put("id", id);
    return portfolioService.send(request);
  }

  @PostMapping("/transfers")
  public JsonNode transfer(@RequestParam int fromAccountId,
                           @RequestParam int toAccountId,
                           @RequestParam double amount,
                           @RequestParam(required = false) String date) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "transfer");
    request.put("from_account_id", fromAccountId);
    request.put("to_account_id", toAccountId);
    request.put("amount", amount);
    if (date != null) {
      request.put("date", (int) LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE).toEpochDay());
    }
    return portfolioService.send(request);
  }

  @GetMapping("/transactions")
  public JsonNode getTransactions(@RequestParam(defaultValue = "1970-01-01") String start,
                                  @RequestParam(defaultValue = "9999-12-31") String end) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "getTransactions");
    request.put("start", (int) LocalDate.parse(start, DateTimeFormatter.ISO_LOCAL_DATE).toEpochDay());
    request.put("end", (int) LocalDate.parse(end, DateTimeFormatter.ISO_LOCAL_DATE).toEpochDay());
    return portfolioService.send(request);
  }

  @GetMapping("/net-worth-at")
  public JsonNode getNetWorthAt(@RequestParam(defaultValue = "1970-01-01") String date) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "netWorthAt");
    request.put("date", (int) LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE).toEpochDay());
    return portfolioService.send(request);
  }

}
