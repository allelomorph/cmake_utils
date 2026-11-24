# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# test for population first in case of use in parent project
if(NOT fmt_POPULATED)
  if(NOT COMMAND FetchContent_Declare OR
      NOT COMMAND FetchContent_MakeAvailable
    )
    include(FetchContent)
  endif()
  # fmt will build static library by default; set BUILD_SHARED_LIBS=ON to build
  #   linked libraries instead
  FetchContent_Declare(fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG        12.2.0
    GIT_SHALLOW
  )
  FetchContent_MakeAvailable(fmt)
  # fmt::fmt should also be available as alias to fmt target
endif()
