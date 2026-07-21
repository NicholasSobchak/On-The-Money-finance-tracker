package com.onthemoney.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.entity.AccountEntity;
import com.onthemoney.service.PlaidService;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/plaid")
@ConditionalOnProperty(name = "plaid.env")
public class PlaidController {

  private final PlaidService plaidService;
  private final ObjectMapper mapper;
  private final String plaidEnv;

  public PlaidController(
      PlaidService plaidService,
      ObjectMapper mapper,
      @Value("${plaid.env:production}") String plaidEnv) {
    this.plaidService = plaidService;
    this.mapper = mapper;
    this.plaidEnv = plaidEnv;
  }

  // POST /api/plaid/link-token - create a link token for iOS Plaid Link
  @PostMapping("/link-token")
  public JsonNode createLinkToken(@RequestBody JsonNode body) {
    String clientUserId = body.has("clientUserId") ? body.get("clientUserId").asText() : "user-1";
    String linkToken = plaidService.createLinkToken(clientUserId);

    var result = mapper.createObjectNode();
    result.put("linkToken", linkToken);
    return result;
  }

  // POST /api/plaid/exchange - exchange public token for access token
  @PostMapping("/exchange")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void exchangeToken(@RequestBody JsonNode body) {
    String publicToken = body.path("publicToken").asText(null);
    String institutionId = body.path("institutionId").asText(null);
    String institutionName = body.path("institutionName").asText("Unknown");

    if (publicToken == null || publicToken.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "publicToken is required");
    }

    plaidService.exchangePublicToken(publicToken, institutionId, institutionName);
  }

  // GET /api/plaid/balances - get balances from all connected institutions
  @GetMapping("/balances")
  public JsonNode getBalances() {
    var accounts = mapper.createArrayNode();
    for (Map<String, Object> account : plaidService.getBalances()) {
      accounts.add(mapper.valueToTree(account));
    }
    var result = mapper.createObjectNode();
    result.set("accounts", accounts);
    return result;
  }

  // GET /api/plaid/transactions?start=2024-01-01&end=2024-12-31
  @GetMapping("/transactions")
  public JsonNode getTransactions(@RequestParam String start, @RequestParam String end) {
    var transactions = mapper.createArrayNode();
    for (Map<String, Object> tx : plaidService.getTransactions(start, end)) {
      transactions.add(mapper.valueToTree(tx));
    }
    var result = mapper.createObjectNode();
    result.set("transactions", transactions);
    return result;
  }

  // POST /api/plaid/sync - fetch Plaid balances and sync into local accounts
  @PostMapping("/sync")
  public List<AccountEntity> syncAccounts() {
    return plaidService.syncAccounts();
  }

  // POST /api/plaid/sandbox-connect - bypass Link for sandbox, exchange token + sync
  @PostMapping("/sandbox-connect")
  public List<AccountEntity> sandboxConnect() {
    if (!"sandbox".equals(plaidEnv)) {
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN, "Sandbox endpoint only available in sandbox environment");
    }
    return plaidService.sandboxConnect();
  }

  // DELETE /api/plaid/item/{id} - remove a connected institution
  @DeleteMapping("/item/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void removeItem(@PathVariable Long id) {
    plaidService.removeItem(id);
  }

  // DELETE /api/plaid/accounts - remove all Plaid-synced accounts
  @DeleteMapping("/accounts")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deletePlaidAccounts() {
    plaidService.deletePlaidAccounts();
  }

  // GET /api/plaid/items/count - number of linked institutions
  @GetMapping("/items/count")
  public JsonNode getLinkedItemCount() {
    var result = mapper.createObjectNode();
    result.put("count", plaidService.getLinkedItemCount());
    return result;
  }
}
