package com.onthemoney.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.entity.AccountEntity;
import com.onthemoney.entity.TransactionEntity;
import com.onthemoney.repository.AccountRepository;
import com.onthemoney.repository.TransactionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.*;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;

@Component
public class PortfolioService {

  private static final Logger log = LoggerFactory.getLogger(PortfolioService.class);

  private Process engine;
  private BufferedWriter toEngine;
  private BufferedReader fromEngine;
  private final ObjectMapper mapper;
  private final AccountRepository accountRepo;
  private final TransactionRepository transactionRepo;

  public PortfolioService(ObjectMapper mapper, AccountRepository accountRepo, TransactionRepository transactionRepo) {
    this.mapper = mapper;
    this.accountRepo = accountRepo;
    this.transactionRepo = transactionRepo;
  }

  // ── Java computations (simple math, no engine needed) ──────

  public double netWorth() {
    return accountRepo.findAll().stream().mapToDouble(AccountEntity::getBalance).sum();
  }

  public double totalAssets() {
    return accountRepo.findAll().stream()
        .filter(a -> a.getBalance() > 0)
        .mapToDouble(AccountEntity::getBalance)
        .sum();
  }

  public double totalLiabilities() {
    return accountRepo.findAll().stream()
        .filter(a -> a.getBalance() < 0)
        .mapToDouble(AccountEntity::getBalance)
        .sum();
  }

  public boolean inTheRed() {
    return netWorth() < 0;
  }

  public boolean inTheGreen() {
    return netWorth() >= 0;
  }

  // ── Engine for heavy computation (lazy-start) ──────────────

  private synchronized void ensureEngineStarted() throws IOException {
    if (engine != null && engine.isAlive()) return;

    var enginePath = Path.of("..", "engine", "build", "src", "finance").toAbsolutePath().normalize();
    if (!enginePath.toFile().exists()) {
      throw new IOException("Engine binary not found at " + enginePath + ". Build the engine first.");
    }
    var pb = new ProcessBuilder(enginePath.toString());
    pb.directory(enginePath.getParent().toFile());
    engine = pb.start();
    toEngine = new BufferedWriter(new OutputStreamWriter(engine.getOutputStream()));
    fromEngine = new BufferedReader(new InputStreamReader(engine.getInputStream()));
    new Thread(() -> {
      try (var err = new BufferedReader(new InputStreamReader(engine.getErrorStream()))) {
        while (err.readLine() != null) {}
      } catch (IOException e) {
        // stderr pipe closed
      }
    }).start();
    log.info("C++ engine started (pid={})", engine.pid());
  }

  public synchronized JsonNode send(JsonNode request) throws IOException {
    ensureEngineStarted();
    toEngine.write(request.toString());
    toEngine.newLine();
    toEngine.flush();

    var line = fromEngine.readLine();
    if (line == null) {
      throw new IOException("engine process terminated unexpectedly");
    }
    return mapper.readTree(line);
  }

  public JsonNode projectRetirement(double initialBalance, double monthlyContribution,
                                    double returnRate, int years, int simulations) throws IOException {
    var request = mapper.createObjectNode();
    request.put("action", "projectRetirement");
    request.put("initialBalance", initialBalance);
    request.put("monthlyContribution", monthlyContribution);
    request.put("returnRate", returnRate);
    request.put("years", years);
    request.put("simulations", simulations);
    return send(request);
  }

  // ── DB operations ──────────────────────────────────────────

  public AccountEntity updateAccount(Long id, String name, Double balance, String accType) {
    var account = accountRepo.findById(id).orElse(null);
    if (account == null) return null;
    if (name != null) account.setName(name);
    if (balance != null) account.setBalance(balance);
    if (accType != null) account.setAccType(accType);
    return accountRepo.save(account);
  }

  public AccountEntity addAccount(String name, double balance, String accType) {
    var account = new AccountEntity();
    account.setName(name);
    account.setBalance(balance);
    account.setAccType(accType);
    return accountRepo.save(account);
  }

  public AccountEntity getAccountById(Long id) {
    return accountRepo.findById(id).orElse(null);
  }

  public AccountEntity getAccountByName(String name) {
    return accountRepo.findByName(name).orElse(null);
  }

  public List<AccountEntity> getAllAccounts() {
    return accountRepo.findAll();
  }

  public TransactionEntity transfer(Long fromAccountId, Long toAccountId, double amount, LocalDate date) {
    var from = accountRepo.findById(fromAccountId).orElse(null);
    var to = accountRepo.findById(toAccountId).orElse(null);
    if (from == null || to == null) return null;

    from.setBalance(from.getBalance() - amount);
    to.setBalance(to.getBalance() + amount);
    accountRepo.save(from);
    accountRepo.save(to);

    var t = new TransactionEntity();
    t.setFromAccountId(fromAccountId);
    t.setToAccountId(toAccountId);
    t.setAmount(amount);
    t.setDate(date != null ? date : LocalDate.now());
    t.setType(2); // Transfer
    t.setDescription("");
    return transactionRepo.save(t);
  }

  public List<TransactionEntity> getTransactions(LocalDate start, LocalDate end) {
    return transactionRepo.findByDateBetween(start, end);
  }

  public void deleteAllAccounts() {
    transactionRepo.deleteAll();
    accountRepo.deleteAll();
  }

  public void deleteAccountById(Long id) {
    accountRepo.deleteById(id);
  }

  public boolean isRunning() {
    return engine != null && engine.isAlive();
  }
}
