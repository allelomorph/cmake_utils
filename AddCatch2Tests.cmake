# newest feature used: cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

include(GetCatch2)

if(NOT COMMAND catch_discover_tests)
  include(Catch)
endif()

# add_catch2_tests(target)
#   Enables ctest integrated testing for targets compiled using the Catch2
#     library, see:
#     - https://github.com/catchorg/Catch2/blob/v3.4.0/docs/cmake-integration.md
#
#   target (string): tests target using Catch2
#   TEST_NAME_REGEX (string, optional): regex to filter for tests in target
#
function(add_catch2_tests target)
  if(NOT TARGET ${target} OR
      NOT BUILD_TESTING)  # set by CTest module
    return()
  endif()

  set(options)
  set(single_value_args TEST_NAME_REGEX)
  set(multi_value_args)
  cmake_parse_arguments(""
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )

  # _CATCH_VERSION_MAJOR intended to allow selective header inclusion to
  #   accommodate both Catch2 v2 and v3 (leading underscore to prevent shadowing
  #   CATCH_VERSION_MAJOR, which may be defined by selected Catch2 headers)
  target_compile_definitions(${target}
    PUBLIC
      _CATCH_VERSION_MAJOR=${Catch2_VERSION_MAJOR}
    )
  target_link_libraries(${target}
    PRIVATE
      Catch2::Catch2WithMain
    )

  # Each discovered test will be run as a separate process, and the Catch2 exit
  #   code for all tests skipped in a process is 4, see:
  #   - https://github.com/catchorg/Catch2/blob/v3.4.0/src/catch2/catch_session.cpp#L348
  # Setting property SKIP_RETURN_CODE uses this to trigger ctest skipping, but is
  #   not implemented until Catch2 v3.7.1, see:
  #   - https://github.com/catchorg/Catch2/issues/2873
  if("${Catch2_VERSION}" VERSION_GREATER_EQUAL "3.7.1")
    catch_discover_tests("${target}")
  else()
    catch_discover_tests("${target}"
      PROPERTIES SKIP_RETURN_CODE 4
    )
  endif()

  # TBD may be better to store command stem in variable defined by init_ctest,
  #   which could add test action memcheck based on toggles
  list(APPEND ctest_command
    "${CMAKE_CTEST_COMMAND}"
    "-C" "$<CONFIGURATION>"
    "--test-action" "memcheck"
    # --output-on-failure will not show output for skipped tests; to inspect
    #   errors on skipped tests use --verbose instead
    "--output-on-failure"
  )
  if(_TEST_NAME_REGEX)
    # If dependencies are fetched and not found, during configuration
    #   dependencies may register their own tests; --tests-regex used here to
    #   filter out any tests not defiend in target. Would prefer to filter by
    #   label, but labels are not properly imported from Catch2 tags, see:
    #   - https://github.com/catchorg/Catch2/issues/1590
    list(APPEND ctest_command
      "--tests-regex" "\"${_TEST_NAME_REGEX}\""
    )
  endif()
  add_custom_command(TARGET "${target}" POST_BUILD
    COMMAND ${ctest_command}
    # Run ctest in same directory as DartConfiguration.tcl, see:
    #  - https://github.com/Kitware/CMake/blob/v3.27.4/Modules/CTestTargets.cmake#L30
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  )

endfunction()
