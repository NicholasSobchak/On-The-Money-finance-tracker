package com.onthemoney.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onthemoney.entity.AccountEntity;
import com.onthemoney.entity.AccountType;
import com.onthemoney.entity.PlaidItemEntity;
import com.onthemoney.repository.AccountRepository;
import com.onthemoney.repository.PlaidItemRepository;
import com.plaid.client.ApiClient;
import com.plaid.client.JSON;
import com.plaid.client.model.*;
import com.plaid.client.request.PlaidApi;
import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import retrofit2.Response;

@Component
@Transactional
@ConditionalOnProperty(name = "plaid.env")
public class PlaidService {

  private final PlaidApi plaidClient;
  private final PlaidItemRepository plaidItemRepo;
  private final AccountRepository accountRepo;
  private final ObjectMapper mapper;
  private final String redirectUri;

  public PlaidService(
      PlaidItemRepository plaidItemRepo,
      AccountRepository accountRepo,
      ObjectMapper mapper,
      @Value("${plaid.client-id}") String clientId,
      @Value("${plaid.secret}") String secret,
      @Value("${plaid.env}") String env,
      @Value("${plaid.redirect-uri:}") String redirectUri) {
    HashMap<String, String> apiKeys = new HashMap<>();
    apiKeys.put("clientId", clientId);
    apiKeys.put("secret", secret);
    ApiClient apiClient = new ApiClient(apiKeys);
    apiClient.setPlaidAdapter(env.equals("production") ? ApiClient.Production : ApiClient.Sandbox);

    // Patch Plaid SDK's Gson to silently handle unknown Products enum values
    // (new Plaid features like identity_match aren't in SDK v9.0.0)
    try {
      java.lang.reflect.Field jsonField = ApiClient.class.getDeclaredField("json");
      jsonField.setAccessible(true);
      JSON plaidJson = (JSON) jsonField.get(apiClient);
      com.google.gson.Gson patchedGson =
          plaidJson
              .getGson()
              .newBuilder()
              .registerTypeAdapter(
                  Products.class,
                  (com.google.gson.JsonDeserializer<Products>)
                      (json, typeOfT, context) -> {
                        if (json.isJsonNull()) return null;
                        String val = json.getAsString();
                        try {
                          return Products.fromValue(val);
                        } catch (IllegalArgumentException e) {
                          return Products.TRANSACTIONS;
                        }
                      })
              .create();
      plaidJson.setGson(patchedGson);

      // Rebuild Retrofit adapter to use the patched Gson
      String baseUrl = apiClient.getAdapterBuilder().build().baseUrl().toString();
      apiClient.setAdapterBuilder(
          new retrofit2.Retrofit.Builder()
              .baseUrl(baseUrl)
              .addConverterFactory(retrofit2.converter.scalars.ScalarsConverterFactory.create())
              .addConverterFactory(
                  retrofit2.converter.gson.GsonConverterFactory.create(patchedGson)));
    } catch (Exception e) {
      // If reflection fails, proceed with default Gson (may fail on unknown enums)
    }

    this.plaidClient = apiClient.createService(PlaidApi.class);
    this.plaidItemRepo = plaidItemRepo;
    this.accountRepo = accountRepo;
    this.mapper = mapper;
    this.redirectUri = redirectUri;
  }

  // 1. Create link token for iOS Plaid Link
  public String createLinkToken(String clientUserId) {
    LinkTokenCreateRequestUser user = new LinkTokenCreateRequestUser().clientUserId(clientUserId);

    LinkTokenCreateRequest request =
        new LinkTokenCreateRequest()
            .user(user)
            .clientName("On The Money")
            .products(Arrays.asList(Products.TRANSACTIONS))
            .countryCodes(Arrays.asList(CountryCode.US))
            .language("en");

    if (redirectUri != null && !redirectUri.isEmpty()) {
      request.setRedirectUri(redirectUri);
    }

    try {
      Response<LinkTokenCreateResponse> response = plaidClient.linkTokenCreate(request).execute();
      if (!response.isSuccessful() || response.body() == null) {
        String errorBody = response.errorBody() != null ? response.errorBody().string() : "unknown";
        throw new RuntimeException("Plaid API error " + response.code() + ": " + errorBody);
      }
      return response.body().getLinkToken();
    } catch (IOException e) {
      throw new RuntimeException("Failed to create Plaid link token", e);
    }
  }

  // 2. Exchange public token -> store access token
  public void exchangePublicToken(
      String publicToken, String institutionId, String institutionName) {
    ItemPublicTokenExchangeRequest request =
        new ItemPublicTokenExchangeRequest().publicToken(publicToken);

    try {
      Response<ItemPublicTokenExchangeResponse> response =
          plaidClient.itemPublicTokenExchange(request).execute();

      PlaidItemEntity item = new PlaidItemEntity();
      item.setAccessToken(response.body().getAccessToken());
      item.setItemId(response.body().getItemId());
      item.setInstitutionId(institutionId);
      item.setInstitutionName(institutionName);
      plaidItemRepo.save(item);
    } catch (IOException e) {
      throw new RuntimeException("Failed to exchange Plaid public token", e);
    }
  }

  // 3. Fetch balances from all connected institutions
  public List<Map<String, Object>> getBalances() {
    List<Map<String, Object>> allAccounts = new ArrayList<>();

    for (PlaidItemEntity item : plaidItemRepo.findAll()) {
      AccountsBalanceGetRequest request =
          new AccountsBalanceGetRequest().accessToken(item.getAccessToken());

      try {
        Response<AccountsGetResponse> response = plaidClient.accountsBalanceGet(request).execute();

        for (AccountBase account : response.body().getAccounts()) {
          Map<String, Object> entry = new HashMap<>();
          entry.put("accountId", account.getAccountId());
          entry.put("name", account.getName());
          entry.put("type", account.getType().getValue());
          entry.put("subtype", account.getSubtype() != null ? account.getSubtype().getValue() : "");
          entry.put("balance", account.getBalances().getCurrent());
          entry.put("availableBalance", account.getBalances().getAvailable());
          entry.put("institution", item.getInstitutionName());
          allAccounts.add(entry);
        }
      } catch (IOException e) {
        throw new RuntimeException("Failed to fetch balances from " + item.getInstitutionName(), e);
      }
    }
    return allAccounts;
  }

  // 4. Fetch transactions
  public List<Map<String, Object>> getTransactions(String start, String end) {
    List<Map<String, Object>> allTransactions = new ArrayList<>();
    LocalDate startDate = LocalDate.parse(start);
    LocalDate endDate = LocalDate.parse(end);

    for (PlaidItemEntity item : plaidItemRepo.findAll()) {
      TransactionsGetRequest request =
          new TransactionsGetRequest()
              .accessToken(item.getAccessToken())
              .startDate(startDate)
              .endDate(endDate);

      try {
        Response<TransactionsGetResponse> response = plaidClient.transactionsGet(request).execute();

        for (Transaction tx : response.body().getTransactions()) {
          Map<String, Object> entry = new HashMap<>();
          entry.put("date", tx.getDate().toString());
          entry.put("name", tx.getName());
          entry.put("amount", tx.getAmount());
          entry.put("category", tx.getCategory());
          entry.put("accountId", tx.getAccountId());
          allTransactions.add(entry);
        }
      } catch (IOException e) {
        throw new RuntimeException(
            "Failed to fetch transactions from " + item.getInstitutionName(), e);
      }
    }
    return allTransactions;
  }

  // 5. Delete a connected institution
  public void removeItem(Long itemId) {
    plaidItemRepo.deleteById(itemId);
  }

  // 6. Sync Plaid balances into local AccountEntity records
  public List<AccountEntity> syncAccounts() {
    List<Map<String, Object>> plaidAccounts = getBalances();

    for (Map<String, Object> plaidAccount : plaidAccounts) {
      String plaidId = (String) plaidAccount.get("accountId");
      String name = (String) plaidAccount.get("name");
      String type = (String) plaidAccount.get("type");
      String subtype = (String) plaidAccount.get("subtype");
      Double balance = (Double) plaidAccount.get("balance");

      AccountType accType = mapPlaidType(type, subtype);

      AccountEntity account =
          accountRepo
              .findByPlaidAccountId(plaidId)
              .orElseGet(
                  () -> {
                    AccountEntity newAccount = new AccountEntity();
                    newAccount.setPlaidAccountId(plaidId);
                    newAccount.setName(name);
                    newAccount.setAccType(accType);
                    return newAccount;
                  });

      account.setBalance(
          balance != null ? new java.math.BigDecimal(balance) : java.math.BigDecimal.ZERO);
      accountRepo.save(account);
    }

    return accountRepo.findAll();
  }

  // 7. Sandbox-only: bypass Plaid Link by creating a public token directly
  public String sandboxPublicTokenCreate() {
    SandboxPublicTokenCreateRequest request =
        new SandboxPublicTokenCreateRequest()
            .institutionId("ins_109508")
            .initialProducts(Arrays.asList(Products.TRANSACTIONS));

    try {
      Response<SandboxPublicTokenCreateResponse> response =
          plaidClient.sandboxPublicTokenCreate(request).execute();
      if (!response.isSuccessful() || response.body() == null) {
        String errorBody = response.errorBody() != null ? response.errorBody().string() : "unknown";
        throw new RuntimeException("Plaid sandbox error " + response.code() + ": " + errorBody);
      }
      return response.body().getPublicToken();
    } catch (IOException e) {
      throw new RuntimeException("Failed to create sandbox public token", e);
    }
  }

  // 8. Sandbox connect: skip if already connected, otherwise create + exchange + sync
  public List<AccountEntity> sandboxConnect() {
    if (!plaidItemRepo.findAll().isEmpty()) {
      return syncAccounts();
    }
    String publicToken = sandboxPublicTokenCreate();
    exchangePublicToken(publicToken, "ins_109508", "First Platypus Bank");
    return syncAccounts();
  }

  // 9. Delete all Plaid-synced accounts and clear plaid items
  public void deletePlaidAccounts() {
    List<AccountEntity> plaidAccounts =
        accountRepo.findAll().stream().filter(a -> a.getPlaidAccountId() != null).toList();
    accountRepo.deleteAll(plaidAccounts);
    plaidItemRepo.deleteAll();
  }

  // 10. Count linked institutions
  public long getLinkedItemCount() {
    return plaidItemRepo.count();
  }

  private AccountType mapPlaidType(String type, String subtype) {
    if ("depository".equals(type)) {
      if ("checking".equals(subtype)) return AccountType.CHECKING;
      if ("savings".equals(subtype)) return AccountType.SAVINGS;
      return AccountType.CHECKING;
    }
    if ("credit".equals(type)) return AccountType.CREDIT_CARD;
    if ("investment".equals(type)) return AccountType.INVESTMENT;
    if ("loan".equals(type)) return AccountType.CREDIT_CARD;
    return AccountType.CHECKING;
  }
}
