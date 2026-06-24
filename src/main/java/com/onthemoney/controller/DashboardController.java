package com.onthemoney.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.entity.AccountType;
import com.onthemoney.service.PortfolioService;
import jakarta.validation.constraints.Positive;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

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

  // Computation endpoints

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
  public JsonNode projectRetirement(
      @RequestParam(defaultValue = "10000") @Positive double initialBalance,
      @RequestParam(defaultValue = "500") @Positive double monthlyContribution,
      @RequestParam(defaultValue = "7") double returnRate,
      @RequestParam(defaultValue = "30") @Positive int years,
      @RequestParam(defaultValue = "10000") @Positive int simulations)
      throws IOException {
    return portfolioService.projectRetirement(
        initialBalance, monthlyContribution, returnRate / 100, years, simulations);
  }

  // Account endpoints

  @PostMapping("/accounts")
  @ResponseStatus(HttpStatus.CREATED)
  public JsonNode addAccount(
      @RequestParam String name,
      @RequestParam @Positive BigDecimal balance,
      @RequestParam AccountType accType) {
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
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(account);
  }

  @GetMapping("/accounts/{id}")
  public JsonNode getAccountById(@PathVariable Long id) {
    var account = portfolioService.getAccountById(id);
    if (account == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(account);
  }

  // Delete endpoints

  @DeleteMapping("/accounts")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteAllAccounts() {
    portfolioService.deleteAllAccounts();
  }

  @DeleteMapping("/accounts/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteAccountById(@PathVariable Long id) {
    portfolioService.deleteAccountById(id);
  }

  @PutMapping("/accounts/{id}")
  public JsonNode updateAccount(
      @PathVariable Long id,
      @RequestParam(required = false) String name,
      @RequestParam(required = false) @Positive BigDecimal balance,
      @RequestParam(required = false) AccountType accType) {
    var account = portfolioService.updateAccount(id, name, balance, accType);
    if (account == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(account);
  }

  // Deposit/Withdraw endpoints

  @PostMapping("/accounts/{id}/deposit")
  @ResponseStatus(HttpStatus.CREATED)
  public JsonNode deposit(
      @PathVariable Long id,
      @RequestParam @Positive BigDecimal amount,
      @RequestParam(required = false) String description,
      @RequestParam(required = false) String date) {
    LocalDate d = parseDate(date);
    var t = portfolioService.deposit(id, amount, description, d);
    if (t == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(t);
  }

  @PostMapping("/accounts/{id}/withdraw")
  @ResponseStatus(HttpStatus.CREATED)
  public JsonNode withdraw(
      @PathVariable Long id,
      @RequestParam @Positive BigDecimal amount,
      @RequestParam(required = false) String description,
      @RequestParam(required = false) String date) {
    LocalDate d = parseDate(date);
    var t = portfolioService.withdraw(id, amount, description, d);
    if (t == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(t);
  }

  // Transfer endpoint

  @PostMapping("/transfers")
  @ResponseStatus(HttpStatus.CREATED)
  public JsonNode transfer(
      @RequestParam Long fromAccountId,
      @RequestParam Long toAccountId,
      @RequestParam @Positive BigDecimal amount,
      @RequestParam(required = false) String date) {
    LocalDate d = parseDate(date);
    var t = portfolioService.transfer(fromAccountId, toAccountId, amount, d);
    if (t == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "account not found");
    }
    return mapper.valueToTree(t);
  }

  // Transaction endpoints

  @GetMapping("/transactions")
  public JsonNode getTransactions(
      @RequestParam(defaultValue = "1970-01-01") String start,
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
  public JsonNode updateTransaction(
      @PathVariable Long id,
      @RequestParam(required = false) @Positive BigDecimal amount,
      @RequestParam(required = false) String description,
      @RequestParam(required = false) String date) {
    LocalDate d = parseDate(date);
    var t = portfolioService.updateTransaction(id, amount, description, d);
    if (t == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "transaction not found");
    }
    return mapper.valueToTree(t);
  }

  @DeleteMapping("/transactions/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteTransaction(@PathVariable Long id) {
    portfolioService.deleteTransaction(id);
  }

  private static LocalDate parseDate(String date) {
    if (date == null) return null;
    try {
      return LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE);
    } catch (DateTimeParseException e) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "invalid date format, expected yyyy-MM-dd");
    }
  }
}
// End DashboardController
