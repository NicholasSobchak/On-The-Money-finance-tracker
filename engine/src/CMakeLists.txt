add_executable(finance
  engine_core/main.cpp
)

target_link_libraries(finance PRIVATE
  nlohmann_json::nlohmann_json
)

# engine_core library and tests kept for reference; not linked into finance
add_library(engine_core STATIC
  engine_core/account.cpp
  engine_core/transaction.cpp
  engine_core/portfolio.cpp
)

target_include_directories(engine_core PUBLIC
  ../include
)

target_link_libraries(engine_core PUBLIC
  nlohmann_json::nlohmann_json
)
