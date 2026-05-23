find_package(Catch2 REQUIRED)
include(Catch)

add_executable(run_tests
  unit/account_tests.cpp
  unit/transaction_tests.cpp
  unit/portfolio_tests.cpp
)

target_link_libraries(run_tests PRIVATE
  Catch2::Catch2WithMain
  engine_core
)

# Register CTest via Catch2
catch_discover_tests(run_tests)
