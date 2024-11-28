# newest feature used: cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

# init_ctest()
#   Assumes configuration of ctest as a dashboard client, and without using a
#     CTestConfig script. Takes variables consumed by CTest module as
#     parameters, see:
#     - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
#
#   Note that due to ctest expecting CTestConfiguration.ini/
#     DartConfiguration.tcl in the build root, these settings apply to all
#     subdirectories, see:
#     - https://github.com/Kitware/CMake/blob/v3.27.4/Modules/CTestTargets.cmake#L30
#
#   Implemented as macro wrapping a function due to cmake's (tested with
#     v3.27.4) consistent failure to generate CTestTestfile scripts when
#     enable_testing() was called anywhere but the scope of the project root
#     listfile.
#
#   Sets CTEST_MEMCHECK_ENABLED if ctest is set up to use
#     `--test-action memcheck`.
#
#   MEMCHECK                       (bool, optional):
#     toggles memcheck on tests
#   MEMCHECK_FAILS_TEST            (bool, optional):
#     toggles memcheck errors failing tests
#   MEMCHECK_GENERATES_SUPPRESSIONS (bool, optional):
#     toggles memcheck generating suppressions file
#
#   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#ctest-memcheck-step
#   MEMORYCHECK_COMMAND_OPTIONS   (list, optional)
#   MEMORYCHECK_SUPPRESSIONS_FILE (string, optional)
#
macro(init_ctest)

  if(NOT DEFINED PROJECT_SOURCE_DIR OR
      NOT DEFINED PROJECT_NAME)
    message(FATAL_ERROR
      "please call init_ctest() after project()")
  endif()

  if(NOT CMAKE_CURRENT_LIST_DIR STREQUAL PROJECT_SOURCE_DIR)
    message(FATAL_ERROR
      "please call init_ctest() in the project root directory")
  endif()

  # Despite being called in CTest module, must be called first in project root
  #   listfile scope to allow for CTestTestfile generation
  enable_testing()

  set(_INIT_CTEST_IMPL_CALLED_FROM_INIT_CTEST YES)
  _init_ctest_impl(${ARGN})
  unset(_INIT_CTEST_IMPL_CALLED_FROM_INIT_CTEST)

endmacro()

# _init_ctest_impl()
#   Internal implementation of init_ctest(), all args are passed in unmodified.
#
function(_init_ctest_impl)
  if(NOT _INIT_CTEST_IMPL_CALLED_FROM_INIT_CTEST)
    message(FATAL_ERROR "_init_ctest_impl() can only be called from init_ctest()")
  endif()

  set(options
    MEMCHECK
    MEMCHECK_FAILS_TEST
    MEMCHECK_GENERATES_SUPPRESSIONS
  )
  # see list of possible args here:
  #   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
  set(single_value_args
    MEMORYCHECK_SUPPRESSIONS_FILE
  )
  set(multi_value_args
    MEMORYCHECK_COMMAND_OPTIONS
    MEMORYCHECK_SANITIZER_OPTIONS
  )
  cmake_parse_arguments(""
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )
  foreach(arg ${single_value_args})
    if(${arg})
      # strip leading underscore from cmake_parse_arguments()
      string(SUBSTRING ${arg} 1 -1 ctest_module_var)
      set(${ctest_module_var} ${{arg}})
    endif()
  endforeach()
  foreach(arg ${multi_value_args})
    if(${arg})
      # strip leading underscore from cmake_parse_arguments()
      string(SUBSTRING ${arg} 1 -1 ctest_module_var)
      # convert to CLI-oriented space delimited string
      list(JOIN ${arg} " " ${ctest_module_var})
    endif()
  endforeach()

  if(_MEMCHECK_FAILS_TEST OR
      _MEMCHECK_GENERATES_SUPPRESSIONS OR
      _MEMORYCHECK_SUPPRESSIONS_FILE OR
      _MEMORYCHECK_COMMAND_OPTIONS OR
      _MEMORYCHECK_SANITIZER_OPTIONS)
    set(_MEMCHECK ON)
  endif()
  if(_MEMCHECK)
    # Preempt CTest module's setting cache var MEMORYCHECK_COMMAND by using
    #   same call to find_program, see:
    #   - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L175
    # This allows for early determination of selected memory checker, and thus
    #   choosing the appropriate memcheck options
    find_program(MEMORYCHECK_COMMAND
      NAMES purify valgrind boundscheck drmemory cuda-memcheck compute-sanitizer
      PATHS "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Rational Software\\Purify\\Setup;InstallFolder]"
      DOC "Path to the memory checking command, used for memory error detection."
    )

    # TBD could not find manuals for purify, boundscheck, drmemory
    # https://docs.nvidia.com/cuda/archive/11.7.0/cuda-memcheck/index.html#memcheck-tool
    # https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html#command-line-options
    if(NOT "${MEMORYCHECK_COMMAND}" MATCHES "^.*/valgrind$")
      message(FATAL_ERROR
        "init_ctest() currently only supports memcheck with valgrind")
    endif()

    if(_MEMORYCHECK_COMMAND_OPTIONS)
      set(memcheck_options ${_MEMORYCHECK_COMMAND_OPTIONS})
    else()
      # Default valgrind options not passed if user supplies any of their own, see:
      #   - https://github.com/Kitware/CMake/blob/v3.30.4/Source/CTest/cmCTestMemCheckHandler.cxx#L584
      set(memcheck_options
        "-q" "--tool=memcheck" "--leak-check=yes" "--show-reachable=yes"
        "--num-callers=50"
      )
    endif()
    if(_MEMCHECK_FAILS_TEST)
      list(APPEND memcheck_options "--error-exitcode=255")
    endif()
    if(_MEMCHECK_GENERATES_SUPPRESSIONS)
      list(APPEND memcheck_options "--gen-suppressions=all")
    endif()
    list(JOIN memcheck_options " " MEMORYCHECK_COMMAND_OPTIONS)

    # MEMORYCHECK_SUPPRESSIONS_FILE is cache set as "" by CTest.cmake as of
    #   v3.30.4, so we intentionally shadow it here with a local value
    if(_MEMORYCHECK_SUPPRESSIONS_FILE)
      set(MEMORYCHECK_SUPPRESSIONS_FILE "${_MEMORYCHECK_SUPPRESSIONS_FILE}")
    endif()

  endif()
  set(CTEST_MEMCHECK_ENABLED ${_MEMCHECK} PARENT_SCOPE)

  # use modern config file name CTestConfiguration.ini over traditional
  #   DartConfiguration.tcl
  set(CTEST_NEW_FORMAT ON)
  include(CTest)
  # option BUILD_TESTING now indicates readiness to add tests

endfunction()


# TBD implement CTest module variables as parameters from:
#   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
#[[
BUILDNAME
CMAKE_COMMAND
COVERAGE_COMMAND
COVERAGE_EXTRA_FLAGS
CTEST_CDASH_VERSION
CTEST_CURL_OPTIONS
CTEST_DROP_SITE_CDASH
CTEST_GIT_INIT_SUBMODULES
CTEST_GIT_UPDATE_CUSTOM
CTEST_LABELS_FOR_SUBPROJECTS
CTEST_P4_CLIENT
CTEST_P4_OPTIONS
CTEST_P4_UPDATE_CUSTOM
CTEST_P4_UPDATE_OPTIONS
CTEST_RESOURCE_SPEC_FILE
CTEST_SUBMIT_INACTIVITY_TIMEOUT
CTEST_SUBMIT_RETRY_COUNT
CTEST_SUBMIT_RETRY_DELAY
CTEST_SVN_OPTIONS
CTEST_TEST_LOAD
CTEST_TLS_VERIFY
CTEST_TLS_VERSION
CTEST_USE_LAUNCHERS
CUDA_SANITIZER_COMMAND
CUDA_SANITIZER_COMMAND_OPTIONS
CVSCOMMAND
CVS_UPDATE_OPTIONS
DART_TESTING_TIMEOUT
DEFAULT_CTEST_CONFIGURATION_TYPE
DRMEMORY_COMMAND
DRMEMORY_COMMAND_OPTIONS
DROP_LOCATION
DROP_METHOD
DROP_SITE
DROP_SITE_PASSWORD
DROP_SITE_USER
GITCOMMAND
GIT_UPDATE_OPTIONS
MAKECOMMAND
MEMORYCHECK_COMMAND
MEMORYCHECK_COMMAND_OPTIONS
MEMORYCHECK_SANITIZER_OPTIONS
MEMORYCHECK_SUPPRESSIONS_FILE
MEMORYCHECK_TYPE
NIGHTLY_START_TIME
P4COMMAND
PROJECT_BINARY_DIR
PROJECT_SOURCE_DIR
PURIFYCOMMAND
SCPCOMMAND
SITE
SUBMIT_URL
SVNCOMMAND
SVN_UPDATE_OPTIONS
TRIGGER_SITE
UPDATE_TYPE
VALGRIND_COMMAND
VALGRIND_COMMAND_OPTIONS

# could be multi-value args, joined into string by ' '
COVERAGE_EXTRA_FLAGS
CTEST_CURL_OPTIONS
CTEST_P4_OPTIONS
CTEST_P4_UPDATE_OPTIONS
CTEST_SVN_OPTIONS
CUDA_SANITIZER_COMMAND_OPTIONS
CVS_UPDATE_OPTIONS
DRMEMORY_COMMAND_OPTIONS
GIT_UPDATE_OPTIONS
MEMORYCHECK_COMMAND_OPTIONS
MEMORYCHECK_SANITIZER_OPTIONS
SVN_UPDATE_OPTIONS
UPDATE_OPTIONS
VALGRIND_COMMAND_OPTIONS

# could be multi-value args, joined into string by ';'
CTEST_LABELS_FOR_SUBPROJECTS
]]
