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

  // ── Computation endpoints ──────────────────────────────────

  @GetMapping("/net-worth")
  public JsonNode getNetWorth() {
    var result = mapper.createObjectNode();
    result.put("netWorth", portfolioService.netWorth());
    return result;
  }

  @GetMapping("/total-assets")
  public JsonNode getTotalAssets() {
    var result = mapper.createObjectNode();
    result.put("totalAssets", portfolioService.totalAssets());
    return result;
  }

  @GetMapping("/total-liabilities")
  public JsonNode getTotalLiabilities() {
    var result = mapper.createObjectNode();
    result.put("totalLiabilities", portfolioService.totalLiabilities());
    return result;
  }

  @GetMapping("/in-the-red")
  public JsonNode getInTheRed() {
    var result = mapper.createObjectNode();
    result.put("inTheRed", portfolioService.inTheRed());
    return result;
  }

  @GetMapping("/in-the-green")
  public JsonNode getInTheGreen() {
    var result = mapper.createObjectNode();
    result.put("inTheGreen", portfolioService.inTheGreen());
    return result;
  }

  @PostMapping("/project")
  public JsonNode projectRetirement(@RequestParam(defaultValue = "10000") double initialBalance,
                                     @RequestParam(defaultValue = "500") double monthlyContribution,
                                     @RequestParam(defaultValue = "7") double returnRate,
                                     @RequestParam(defaultValue = "30") int years,
                                     @RequestParam(defaultValue = "10000") int simulations) throws IOException {
    return portfolioService.projectRetirement(initialBalance, monthlyContribution, returnRate / 100, years, simulations);
  }

  // ── Account endpoints ──────────────────────────────────────

  @PostMapping("/accounts")
  public JsonNode addAccount(@RequestParam String name,
                              @RequestParam double balance,
                              @RequestParam String accType) {
    var account = portfolioService.addAccount(name, balance, accType);
    return mapper.valueToTree(account);
  }

  @GetMapping("/accounts")
  public JsonNode getAccounts(@RequestParam(defaultValue = "all") String name) {
    if ("all".equals(name)) {
      return mapper.valueToTree(portfolioService.getAllAccounts());
    }
    var account = portfolioService.getAccountByName(name);
    if (account == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(account);
  }

  @GetMapping("/accounts/{id}")
  public JsonNode getAccountById(@PathVariable Long id) {
    var account = portfolioService.getAccountById(id);
    if (account == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(account);
  }

  // ── Delete endpoints ──────────────────────────────────────

  @DeleteMapping("/accounts")
  public JsonNode deleteAllAccounts() {
    portfolioService.deleteAllAccounts();
    var ok = mapper.createObjectNode();
    ok.put("status", "ok");
    return ok;
  }

  @DeleteMapping("/accounts/{id}")
  public JsonNode deleteAccountById(@PathVariable Long id) {
    portfolioService.deleteAccountById(id);
    var ok = mapper.createObjectNode();
    ok.put("status", "ok");
    return ok;
  }

  @PutMapping("/accounts/{id}")
  public JsonNode updateAccount(@PathVariable Long id,
                                 @RequestParam(required = false) String name,
                                 @RequestParam(required = false) Double balance,
                                 @RequestParam(required = false) String accType) {
    var account = portfolioService.updateAccount(id, name, balance, accType);
    if (account == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(account);
  }

  // ── Deposit/Withdraw endpoints ─────────────────────────────

  @PostMapping("/accounts/{id}/deposit")
  public JsonNode deposit(@PathVariable Long id,
                           @RequestParam double amount,
                           @RequestParam(required = false) String description,
                           @RequestParam(required = false) String date) {
    LocalDate d = date != null ? LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE) : null;
    var t = portfolioService.deposit(id, amount, description, d);
    if (t == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(t);
  }

  @PostMapping("/accounts/{id}/withdraw")
  public JsonNode withdraw(@PathVariable Long id,
                            @RequestParam double amount,
                            @RequestParam(required = false) String description,
                            @RequestParam(required = false) String date) {
    LocalDate d = date != null ? LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE) : null;
    var t = portfolioService.withdraw(id, amount, description, d);
    if (t == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(t);
  }

  // ── Transfer endpoint ──────────────────────────────────────

  @PostMapping("/transfers")
  public JsonNode transfer(@RequestParam Long fromAccountId,
                            @RequestParam Long toAccountId,
                            @RequestParam double amount,
                            @RequestParam(required = false) String date) {
    LocalDate d = date != null ? LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE) : null;
    var t = portfolioService.transfer(fromAccountId, toAccountId, amount, d);
    if (t == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "account not found");
      return err;
    }
    return mapper.valueToTree(t);
  }

  // ── Transaction endpoints ──────────────────────────────────

  @GetMapping("/transactions")
  public JsonNode getTransactions(@RequestParam(defaultValue = "1970-01-01") String start,
                                  @RequestParam(defaultValue = "9999-12-31") String end,
                                  @RequestParam(required = false) Long accountId) {
    if (accountId != null) {
      return mapper.valueToTree(portfolioService.getTransactionsByAccount(accountId));
    }
    var startDate = LocalDate.parse(start, DateTimeFormatter.ISO_LOCAL_DATE);
    var endDate = LocalDate.parse(end, DateTimeFormatter.ISO_LOCAL_DATE);
    return mapper.valueToTree(portfolioService.getTransactions(startDate, endDate));
  }

  @PutMapping("/transactions/{id}")
  public JsonNode updateTransaction(@PathVariable Long id,
                                     @RequestParam(required = false) Double amount,
                                     @RequestParam(required = false) String description,
                                     @RequestParam(required = false) String date) {
    LocalDate d = date != null ? LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE) : null;
    var t = portfolioService.updateTransaction(id, amount, description, d);
    if (t == null) {
      var err = mapper.createObjectNode();
      err.put("status", "error");
      err.put("message", "transaction not found");
      return err;
    }
    return mapper.valueToTree(t);
  }

  @DeleteMapping("/transactions/{id}")
  public JsonNode deleteTransaction(@PathVariable Long id) {
    portfolioService.deleteTransaction(id);
    var ok = mapper.createObjectNode();
    ok.put("status", "ok");
    return ok;
  }
}
