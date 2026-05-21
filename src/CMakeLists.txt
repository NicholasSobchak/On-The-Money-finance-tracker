add_library(app STATIC
  app/account.cpp
  app/transaction.cpp
  app/portfolio.cpp
)

target_include_directories(app PUBLIC
  ../include
)

add_executable(finance
  app/main.cpp
)

target_link_libraries(finance PRIVATE
  app
)
