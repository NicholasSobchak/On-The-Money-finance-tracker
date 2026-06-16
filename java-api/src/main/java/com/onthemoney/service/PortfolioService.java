package com.onthemoney.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.onthemoney.entity.AccountEntity;
import com.onthemoney.entity.TransactionEntity;
import com.onthemoney.repository.AccountRepository;
import com.onthemoney.repository.TransactionRepository;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
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

  @PostConstruct
  public void startEngine() throws IOException {
    var enginePath = Path.of("..", "engine", "build", "src", "finance").toAbsolutePath().normalize();
    if (!enginePath.toFile().exists()) {
      log.warn("Engine binary not found at {}. Build the engine first.", enginePath);
      return;
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

  // ── Pipe communication ──────────────────────────────────────

  public synchronized JsonNode send(JsonNode request) throws IOException {
    if (engine == null || !engine.isAlive()) {
      throw new IOException("engine is not running");
    }
    toEngine.write(request.toString());
    toEngine.newLine();
    toEngine.flush();

    var line = fromEngine.readLine();
    if (line == null) {
      throw new IOException("engine process terminated unexpectedly");
    }
    return mapper.readTree(line);
  }

  // ── Computation (sends data + action to engine) ────────────

  private JsonNode compute(String action) throws IOException {
    var accounts = accountRepo.findAll();
    var request = mapper.createObjectNode();
    request.put("action", action);
    request.set("accounts", mapper.valueToTree(accounts));
    return send(request);
  }

  public JsonNode getNetWorth() throws IOException {
    return compute("getNetWorth");
  }

  public JsonNode getTotalAssets() throws IOException {
    return compute("getTotalAssets");
  }

  public JsonNode getTotalLiabilities() throws IOException {
    return compute("totalLiabilities");
  }

  public JsonNode getInTheRed() throws IOException {
    return compute("inTheRed");
  }

  public JsonNode getInTheGreen() throws IOException {
    return compute("inTheGreen");
  }

  public JsonNode getNetWorthAt(LocalDate date) throws IOException {
    var accounts = accountRepo.findAll();
    var request = mapper.createObjectNode();
    request.put("action", "netWorthAt");
    request.put("date", (int) date.toEpochDay());
    request.set("accounts", mapper.valueToTree(accounts));
    return send(request);
  }

  // ── DB operations (Java writes to PostgreSQL directly) ─────

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
    if (from == null || to == null) {
      return null;
    }

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

  // ── Engine lifecycle ───────────────────────────────────────

  public boolean isRunning() {
    return engine != null && engine.isAlive();
  }

  @PreDestroy
  public void stopEngine() {
    if (engine != null && engine.isAlive()) {
      engine.destroyForcibly();
      log.info("C++ engine stopped");
    }
  }
}
