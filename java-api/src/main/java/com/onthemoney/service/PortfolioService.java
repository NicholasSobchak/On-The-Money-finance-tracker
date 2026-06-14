package com.onthemoney.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.*;
import java.nio.file.Path;

@Component
public class PortfolioService {

  private static final Logger log = LoggerFactory.getLogger(PortfolioService.class);

  private Process engine;
  private BufferedWriter toEngine;
  private BufferedReader fromEngine;
  private final ObjectMapper mapper;

  public PortfolioService(ObjectMapper mapper) {
    this.mapper = mapper;
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
    log.info("C++ engine started (pid={})", engine.pid());
  }

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
