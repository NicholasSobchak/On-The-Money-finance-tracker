add_library(engine_core STATIC
  engine_core/account.cpp
  engine_core/transaction.cpp
  engine_core/portfolio.cpp
)

target_include_directories(engine_core PUBLIC
  ../include
)

add_executable(finance
  engine_core/main.cpp
)

target_link_libraries(finance PRIVATE
  engine_core
)
