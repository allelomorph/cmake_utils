# most recent features used: CMAKE_CXX_CPPLINT 3.8, CMAKE_CXX_CPPCHECK 3.10
cmake_minimum_required(VERSION 3.10)

include_guard(GLOBAL)

# set_up_integrated_static_analyzers()
#   Sets the following cache variables, thus enabling cmake-supported static
#   analysis with any of the four programs present:
#     - CMAKE_CXX_CLANG_TIDY
#     - CMAKE_CXX_CPPCHECK
#     - CMAKE_CXX_CPPLINT
#     - CMAKE_CXX_INCLUDE_WHAT_YOU_USE
#   If any program is not found, its analysis is skipped with a warning.
#
macro(set_up_integrated_static_analyzers)

  # generate compile_commands.json
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  find_program(CLANG_TIDY_BINARY
    NAMES
      clang-tidy
  )
  if(CLANG_TIDY_BINARY)
    if(NOT DEFINED CMAKE_CXX_CLANG_TIDY)
      list(APPEND CLANG_TIDY_COMMAND
        "${CLANG_TIDY_BINARY}"
        "--checks=-llvmlibc-*"
        "--warnings-as-errors=*"
        "-p" "${CMAKE_BINARY_DIR}"  # provide location of compile_commands.json
      )
      set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}" CACHE STRING
        "default clang-tidy command line for any files")
    endif()
  else()
    message(WARNING "clang-tidy not found, skipping use as static analyzer")
  endif()

  # cpplint errors will not stop build and are only issued as warnings (plain
  #   text, not message(WARNING),) see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L475
  find_program(CPPLINT_BINARY
    NAMES
      cpplint
  )
  if(CPPLINT_BINARY)
    if(NOT DEFINED CMAKE_CXX_CPPLINT)
      list(APPEND CPPLINT_COMMAND
        "${CPPLINT_BINARY}"
        "--filter=-legal"
      )
      set(CMAKE_CXX_CPPLINT "${CPPLINT_COMMAND}" CACHE STRING
        "default cpplint command line for any files")
    endif()
  else()
    message(WARNING "cpplint not found, skipping use as static analyzer")
  endif()

  find_program(CPPCHECK_BINARY
    NAMES
      cppcheck
  )
  if(CPPCHECK_BINARY)
    if(NOT DEFINED CMAKE_CXX_CPPCHECK)
      list(APPEND CPPCHECK_COMMAND
        "${CPPCHECK_BINARY}"
        "--enable=all"
        "--disable=missingInclude,unusedFunction"
        "--error-exitcode=1"
      )
      set(CMAKE_CXX_CPPCHECK "${CPPCHECK_COMMAND}" CACHE STRING
        "default cppcheck command line for any files")
    endif()
  else()
    message(WARNING "cppcheck not found, skipping use as static analyzer")
  endif()

  # include-what-you-use errors only issued as warnings (not message(WARNING))
  #   unless using --error to set exit code, see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L363
  find_program(INCLUDE_WHAT_YOU_USE_BINARY
    NAMES
      include-what-you-use
      iwyu
  )
  if(INCLUDE_WHAT_YOU_USE_BINARY)
    if(NOT DEFINED CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
      list(APPEND INCLUDE_WHAT_YOU_USE_COMMAND
        "${INCLUDE_WHAT_YOU_USE_BINARY}"
        "-Xiwyu"  # enables long opts other than --version and --help
        "--error"  # sets error exit code (default 1)
      )
      set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE "${INCLUDE_WHAT_YOU_USE_COMMAND}" CACHE STRING
        "default include-what-you-use command line for any files")
    endif()
  else()
    message(WARNING "include-what-you-use not found, skipping use as static analyzer")
  endif()

  #set(CMAKE_LINK_WHAT_YOU_USE ON CACHE BOOL
  #  "toggles checking for unused links to ELF targets" FORCE)
  # see also CMAKE_LINK_WHAT_YOU_USE_CHECK (v3.22,) "This check is currently
  #   only defined on ELF platforms with value `ldd -u -r`."

endmacro()
