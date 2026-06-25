# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# test for population first in case of use in parent project
if(NOT nlohmann_json_POPULATED)
  if(NOT COMMAND FetchContent_Declare OR
      NOT COMMAND FetchContent_MakeAvailable
    )
    include(FetchContent)
  endif()
  FetchContent_Declare(nlohmann_json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG        v3.12.0
    GIT_SHALLOW
  )
  FetchContent_MakeAvailable(nlohmann_json)
  # link to nlohmann_json::nlohmann_json target
endif()
