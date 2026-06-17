add_library(engine_core STATIC
  engine_core/engine_core.cpp
)

target_include_directories(engine_core PUBLIC
  ../include
)

target_link_libraries(engine_core PUBLIC
  nlohmann_json::nlohmann_json
)

add_executable(finance
  engine_core/main.cpp
)

target_link_libraries(finance PRIVATE
  engine_core
)
