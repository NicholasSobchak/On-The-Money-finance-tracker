FROM ubuntu:24.04 AS engine-builder
RUN apt-get update && apt-get install -y \
    cmake g++ nlohmann-json3-dev catch2 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /engine
COPY engine/CMakeLists.txt engine/vcpkg.json ./
COPY engine/src src
COPY engine/include include
COPY engine/tests tests
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j"$(nproc)" --target run_engine && \
    cp build/src/run_engine /run_engine

FROM eclipse-temurin:17-jdk AS java-builder
WORKDIR /app-build
COPY app/gradlew app/build.gradle app/settings.gradle ./
COPY app/gradle gradle
RUN ./gradlew dependencies --no-daemon
COPY app/src src
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:17-jre
RUN groupadd -r appuser && useradd -r -g appuser appuser
COPY --from=engine-builder /run_engine /app/run_engine
COPY --from=java-builder /app-build/build/libs/*.jar /app/app.jar
RUN chown -R appuser:appuser /app
USER appuser
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-Xmx512m", "-jar", "/app/app.jar"]
