# newest feature used: cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

# integrate_catch2_testing(target)
#   Enables ctest integrated testing for targets compiled using the Catch2
#     library, see:
#     - https://github.com/catchorg/Catch2/blob/v3.4.0/docs/cmake-integration.md
#
#   target (string): tests target using Catch2
#   MEMCHECK (bool, optional): toggles valgrind memcheck on tests
#   MEMCHK_SUPPR_FILE (string, optional): path to valgrind suppressions file
#   TEST_NAME_REGEX (string, optional): regex to filter for tests in target
#
function(integrate_catch2_testing target)
  if(NOT TARGET ${target})
    return()
  endif()

  set(options MEMCHECK)
  set(single_value_args MEMCHK_SUPPR_FILE TEST_NAME_REGEX)
  set(multi_value_args)
  cmake_parse_arguments(CATCH2_TARGET
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )

  include(GetCatch2)
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

  if(CATCH2_TARGET_MEMCHECK OR CATCH2_TARGET_MEMCHK_SUPPR_FILE)
    # In this case, when using memory checking on tests we want it to:
    #   - fail with a non-zero exit code on error (causes test case to fail)
    #   - generate suppressions on error
    #   - use a suppressions file
    # CMake docs would indicate the use of CTEST_MEMORYCHECK_COMMAND_OPTIONS and
    #   CTEST_MEMORYCHECK_SUPPRESSIONS_FILE, but two issues:
    #   - only when using a CTest client script:
    #     - https://cmake.org/cmake/help/latest/manual/ctest.1.html#dashboard-client-via-ctest-script
    #   - these variables seem to be deactivated in cmake-supplied scripts:
    #     - https://github.com/Kitware/CMake/blob/v3.30.4/Templates/CTestScript.cmake.in#L16
    # As an alternative, one can set related undocumented variables
    #   MEMORYCHECK_COMMAND_OPTIONS and MEMORYCHECK_SUPPRESSIONS_FILE, used by
    #   DartConfiguration.tcl.in to set MemoryCheckCommandOptions and
    #   MemoryCheckSuppressionFile, which are then used by ctest memcheck, see:
    #       - https://stackoverflow.com/a/56116311
    #       - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L264
    #       - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTestTargets.cmake#L40
    #       - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/DartConfiguration.tcl.in#L80

    # preemptively set cache var MEMORYCHECK_COMMAND using same call to
    #   find_program made in CTest.cmake, see:
    #   - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L175
    #   this allows for early determination of selected memory checker, and thus
    #   choose the appropriate memcheck options
    find_program(MEMORYCHECK_COMMAND
      NAMES purify valgrind boundscheck drmemory cuda-memcheck compute-sanitizer
      PATHS "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Rational Software\\Purify\\Setup;InstallFolder]"
      DOC "Path to the memory checking command, used for memory error detection."
    )

    # TBD could not find manuals for purify, boundscheck, drmemory
    # https://docs.nvidia.com/cuda/archive/11.7.0/cuda-memcheck/index.html#memcheck-tool
    # https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html#command-line-options
    if("${MEMORYCHECK_COMMAND}" MATCHES "^.*/valgrind$")
      # default valgrind options not passed if user supplies any of their own, see:
      #   - https://github.com/Kitware/CMake/blob/v3.30.4/Source/CTest/cmCTestMemCheckHandler.cxx#L584
      set(MEMCHECK_OPTIONS
        "-q"
        "--tool=memcheck"
        "--leak-check=yes"
        "--show-reachable=yes"
        "--num-callers=50"
      )
      # https://www.man7.org/linux/man-pages/man1/valgrind.1.html
      list(APPEND MEMCHECK_OPTIONS
        "--error-exitcode=255"
        "--gen-suppressions=all"
      )
    else()
      message(WARNING "memcheck suppression generation and exit code control only \
available when using valgrind")
    endif()
    # MEMORYCHECK_COMMAND_OPTIONS parsed by cmake as string, not list; can be
    #   non-cache variable
    list(JOIN MEMCHECK_OPTIONS " " MEMORYCHECK_COMMAND_OPTIONS)

    # much like with MEMORYCHECK_COMMAND, we can set the cache var first by
    #   preempting a similar call in CTest.cmake, see:
    #   - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L181
    set(MEMORYCHECK_SUPPRESSIONS_FILE
      "${CMAKE_CURRENT_LIST_DIR}/SDL2.supp" CACHE FILEPATH
      "File that contains suppressions for the memory checker"
    )
  endif()

  # consumes MEMORYCHECK_* to set up DartConfiguration.tcl
  # calls enable_testing(), but in practice enable_testing() must first be
  #   called in project root lists file
  include(CTest)

  if(NOT COMMAND catch_discover_tests)
    include(Catch)
  endif()

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

  list(APPEND ctest_command
    "ctest"
    "-C" "$<CONFIGURATION>"
    "--test-action" "memcheck"
    # --output-on-failure will not show output for skipped tests; to inspect
    #   errors on skipped tests use --verbose instead
    "--output-on-failure"
  )
  if(CATCH2_TARGET_TEST_NAME_REGEX)
    # If dependencies are fetched and not found, during configuration
    #   dependencies may register their own tests; --tests-regex used here to
    #   filter out any tests not defiend in target. Would prefer to filter by
    #   label, but labels are not properly imported from Catch2 tags, see:
    #   - https://github.com/catchorg/Catch2/issues/1590
    list(APPEND ctest_command
      "--tests-regex" "\"${CATCH2_TARGET_TEST_NAME_REGEX}\""
    )
  endif()
  add_custom_command(TARGET "${target}" POST_BUILD
    COMMAND ${ctest_command}
    # As of cmake 3.27.4, DartConfiguration.tcl placed in PROJECT_BINARY_DIR
    #  regardless of where enable_testing()/include(CTest) is called, see:
    #  - https://github.com/Kitware/CMake/blob/v3.27.4/Modules/CTestTargets.cmake#L30
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  )

endfunction()
