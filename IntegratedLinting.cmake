# most recent features used: CMAKE_CXX_CPPLINT 3.8, CMAKE_CXX_CPPCHECK 3.10
cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# init_integrated_linting()
#   Sets the following cache variables, intended for use by integrate_linting():
#     - _CMAKE_CXX_CLANG_TIDY
#     - _CMAKE_CXX_CPPCHECK
#     - _CMAKE_CXX_CPPLINT
#     - _CMAKE_CXX_INCLUDE_WHAT_YOU_USE
#
#   CMake docs recommend integrating linting by setting linter commands to
#     CMAKE_CXX_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE, which in turn
#     will set CXX_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE for every
#     compiled target. In practice, it seems much easier to opt in to linting
#     on a per-target basis, to help prevent unwanted linting of depedencies
#     downloaded with FetchContent, for example.
#
macro(init_integrated_linting)
  if(NOT CMAKE_EXPORT_COMPILE_COMMANDS)
    if("${CMAKE_CURRENT_LIST_DIR}" STREQUAL "${PROJECT_SOURCE_DIR}")
      set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    else()
      message(FATAL_ERROR "`set(CMAKE_EXPORT_COMPILE_COMMANDS ON)` required in \
project root lists file")
    endif()
  endif()

  # clang-tidy errors will always stop the build, see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L419
  if(NOT DEFINED _CMAKE_CXX_CLANG_TIDY)
    find_program(CLANG_TIDY_BINARY
      NAMES clang-tidy
    )
    if(CLANG_TIDY_BINARY)
      list(APPEND CLANG_TIDY_COMMAND
        "${CLANG_TIDY_BINARY}"
        "--checks=-llvmlibc-*"
        "--warnings-as-errors=*"
        "-p" "${CMAKE_BINARY_DIR}"  # provide location of compile_commands.json
      )
      set(_CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}" CACHE STRING
        "default clang-tidy command line for linting files")
    else()
      message(WARNING "clang-tidy not found, skipping use as linter")
      set(_CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_BINARY}" CACHE STRING
        "default clang-tidy command line for linting files")
    endif()
  endif()

  # cpplint errors will never stop the build and are only issued as warnings
  #   (plain text, not message(WARNING),) see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L475
  if(NOT DEFINED _CMAKE_CXX_CPPLINT)
    find_program(CPPLINT_BINARY
      NAMES cpplint
    )
    if(CPPLINT_BINARY)
      list(APPEND CPPLINT_COMMAND
        "${CPPLINT_BINARY}"
        "--filter=-legal,-build/include_subdir"
      )
      set(_CMAKE_CXX_CPPLINT "${CPPLINT_COMMAND}" CACHE STRING
        "default cpplint command line for linting files")
    else()
      message(WARNING "cpplint not found, skipping use as linter")
      set(_CMAKE_CXX_CPPLINT "${CPPLINT_BINARY}" CACHE STRING
        "default cpplint command line for linting files")
    endif()
  endif()

  # cppcheck by default should not stop the build when reporting errors, see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L529
  #   (this can be toggled by passing --error-exitcode)
  if(NOT DEFINED _CMAKE_CXX_CPPCHECK)
    find_program(CPPCHECK_BINARY
      NAMES cppcheck
    )
    if(CPPCHECK_BINARY)
      list(APPEND CPPCHECK_COMMAND
        "${CPPCHECK_BINARY}"
        "--enable=all"
        "--disable=missingInclude,unusedFunction"
        "--error-exitcode=1"
        "--project=${CMAKE_BINARY_DIR}/compile_commands.json"
        # do not check files in fetched dependencies
        "-i" "*${CMAKE_BINARY_DIR}/_deps/*"
        # suppress errors from code included from fetched dependencies
        "--suppress=*:*${CMAKE_BINARY_DIR}/_deps/*"
      )
      set(_CMAKE_CXX_CPPCHECK "${CPPCHECK_COMMAND}" CACHE STRING
        "default cppcheck command line for linting files")
    else()
      message(WARNING "cppcheck not found, skipping use as linter")
      set(_CMAKE_CXX_CPPCHECK "${CPPCHECK_BINARY}" CACHE STRING
        "default cppcheck command line for linting files")
    endif()
  endif()

  # include-what-you-use errors only issued as warnings (not message(WARNING))
  #   unless using --error to set exit code, see:
  #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L363
  if(NOT DEFINED _CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
    find_program(INCLUDE_WHAT_YOU_USE_BINARY
      NAMES include-what-you-use iwyu
    )
    if(INCLUDE_WHAT_YOU_USE_BINARY)
      # -Xiwyu needed before every iwyu option other than --version and --help
      list(APPEND INCLUDE_WHAT_YOU_USE_COMMAND
        "${INCLUDE_WHAT_YOU_USE_BINARY}"
        "-Xiwyu" "--cxx17ns"
      )
      set(_CMAKE_CXX_INCLUDE_WHAT_YOU_USE
        "${INCLUDE_WHAT_YOU_USE_COMMAND}" CACHE STRING
        "default include-what-you-use command line for linting files")
    else()
      message(WARNING "include-what-you-use not found, skipping use as linter")
      set(_CMAKE_CXX_INCLUDE_WHAT_YOU_USE
        "${INCLUDE_WHAT_YOU_USE_BINARY}" CACHE STRING
        "default include-what-you-use command line for linting files")
    endif()
  endif()

  # https://cmake.org/cmake/help/v3.30/variable/CMAKE_LINK_WHAT_YOU_USE.html
  # https://cmake.org/cmake/help/v3.30/variable/CMAKE_LINK_WHAT_YOU_USE_CHECK.html
  #set(_CMAKE_LINK_WHAT_YOU_USE ${CMAKE_LINK_WHAT_YOU_USE_CHECK} CACHE STRING
  #  "default command line for checking for unused links to targets")

endmacro()

# integrated_linting(target)
#   Uses cached _CMAKE_CXX_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE
#     to set CXX_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE on a per
#     target basis.
#
#   target (string): target to set properties
#
function(integrated_linting target)
  if(NOT TARGET "${target}")
    return()
  endif()

  # sets cache vars, so should only run on first call
  if(NOT DEFINED _CMAKE_CXX_CLANG_TIDY OR
      NOT DEFINED _CMAKE_CXX_CPPCHECK OR
      NOT DEFINED _CMAKE_CXX_CPPLINT OR
      NOT DEFINED _CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
    init_integrated_linting()
  endif()

  if(_CMAKE_CXX_CLANG_TIDY)
    # clang-tidy is only compatible with precompiled headers generated with clang, see:
    #   - https://stackoverflow.com/a/76932426
    get_target_property(
      _INTERFACE_PRECOMPILE_HEADERS "${target}" INTERFACE_PRECOMPILE_HEADERS)
    get_target_property(
      _PRECOMPILE_HEADERS "${target}" PRECOMPILE_HEADERS)
    if(NOT (_INTERFACE_PRECOMPILE_HEADERS OR _PRECOMPILE_HEADERS) OR
        "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")  # Clang or AppleClang
      set_target_properties("${target}" PROPERTIES
        CXX_CLANG_TIDY "${_CMAKE_CXX_CLANG_TIDY}")
    endif()
  endif()

  if(_CMAKE_CXX_CPPCHECK)
    set_target_properties("${target}" PROPERTIES
      CXX_CPPCHECK "${_CMAKE_CXX_CPPCHECK}")
  endif()

  if(_CMAKE_CXX_CPPLINT)
    set_target_properties("${target}" PROPERTIES
      CXX_CPPLINT "${_CMAKE_CXX_CPPLINT}")
  endif()

  if(_CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
    set_target_properties("${target}" PROPERTIES
      CXX_INCLUDE_WHAT_YOU_USE "${_CMAKE_CXX_INCLUDE_WHAT_YOU_USE}")
  endif()

endfunction()
