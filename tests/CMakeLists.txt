find_package(Catch2 REQUIRED)
include(Catch)

add_executable(run_tests
  unit/portfolio_tests.cpp
)

target_link_libraries(run_tests PRIVATE
  Catch2::Catch2WithMain
  app
)

# Register CTest via Catch2
catch_discover_tests(run_tests)
