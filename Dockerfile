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

FROM eclipse-temurin:17-jdk-alpine AS java-builder
WORKDIR /app
COPY gradlew build.gradle ./
COPY gradle gradle
RUN ./gradlew dependencies --no-daemon
COPY src src
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:17-jre
COPY --from=engine-builder /run_engine /app/run_engine
COPY --from=java-builder /app/build/libs/*.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
