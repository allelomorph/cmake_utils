# newest feature used: cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

define_property(GLOBAL PROPERTY
  ${PROJECT_NAME}_CTEST_INITIALIZED
  BRIEF_DOCS "Used by init_ctest() to prevent it from being called more than \
once per [sub]project."
)

# init_ctest()
#   Wrapper for enable_testing() and include(CTest) to allow for per-project
#     configuration of ctest even when there are multiple subprojects.
#
#   Limits all ctest config variables to their defaults, except for memcheck,
#     which can be configured with MEMCHECK_* params instead (**only valgrind is
#     currently supported**.)
#
#   Upon return:
#     - a CTestConfiguration.ini (historically DartConfiguration.tcl) file will
#         be set in the [sub]project build directory to be read by ctest
#     - cmake global property ${PROJECT_NAME}_CTEST_INITIALIZED will be set to
#         TRUE
#     - ${PROJECT_NAME}_CTEST_MEMCHECK_ENABLED will be cached as a bool to
#         indicate if ctest is set up to use `--test-action memcheck`
#     - cmake global property CTEST_TARGETS_ADDED will be set to 1 if not already
#     - a generic `test` target will be added if not already
#     - a suite of specialized testing targets will be added if not already, eg
#         Continuous*, Experimental*, Nightly*
#     - !!! unlike when calling `include(CTest)`, BUILD_TESTING will not be
#         cached as ON by default - its state from before init_ctest will be
#         preserved
#
#   Notes:
#     - assumes that user is not using CTestConfig or DartConfig scripts, see:
#       - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
#     - implemented as macro wrapping a function due to cmake's (tested with
#       v3.27.4) consistent failure to generate CTestTestfile scripts when
#       enable_testing() was called anywhere but the scope of the project root
#       listfile
#     - due to ctest expecting CTestConfiguration.ini/DartConfiguration.tcl in
#       the build root, these settings apply to all project subdirectories, see:
#       - https://github.com/Kitware/CMake/blob/v3.27.4/Modules/CTestTargets.cmake#L30
#
#   MEMCHECK                        (bool, optional):
#     toggles memcheck on tests
#   MEMCHECK_FAILS_TEST             (bool, optional):
#     toggles memcheck errors failing tests
#   MEMCHECK_GENERATES_SUPPRESSIONS (bool, optional):
#     toggles memcheck generating suppressions file
#   MEMCHECK_SUPPRESSIONS_FILE      (string, optional):
#     path to memcheck suppressions file
#   MEMCHECK_COMMAND_OPTIONS        (list, optional):
#     additional memcheck cli options
#
macro(init_ctest)

  get_cmake_property(ctest_initialized ${PROJECT_NAME}_CTEST_INITIALIZED)
  if(ctest_initialized)
    message(FATAL_ERROR
      "please only call init_ctest() once per [sub]project")
  endif()

  if(PROJECT_IS_TOP_LEVEL AND
      NOT DEFINED PROJECT_SOURCE_DIR OR
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

  set(_inside_init_ctest YES)
  _init_ctest_impl(${ARGN})
  unset(_inside_init_ctest)

endmacro()

# _init_ctest_impl()
#   Implementation details of init_ctest(). All parameters are passed in
#     unmodified.
#
function(_init_ctest_impl)

  if(NOT _inside_init_ctest)
    message(FATAL_ERROR
      "_init_ctest_impl() can only be called as part of init_ctest()")
  endif()

  ##
  ## Record state of BUILD_TESTING
  ##

  if(DEFINED BUILD_TESTING)
    set(_BUILD_TESTING_defined ON)
  else()
    set(_BUILD_TESTING_defined OFF)
  endif()
  if(DEFINED CACHE{BUILD_TESTING})
    set(_BUILD_TESTING_cached ON)
  else()
    set(_BUILD_TESTING_cached OFF)
  endif()
  if(_BUILD_TESTING_defined OR _BUILD_TESTING_cached)
    if(NOT BUILD_TESTING)
      return()
    endif()
    set(_BUILD_TESTING_value ${BUILD_TESTING})
  endif()

  ##
  ## Restrict use of CTest module variables to defaults
  ##

  # Variables used to configure DartConfiguration.tcl, see:
  #   - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/CTest.cmake
  #   - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/DartConfiguration.tcl.in
  #   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
  set(ctest_uncached_dart_config_vars
    BUILDNAME                        # CTest default: (derived from system and compiler names)
    #CMAKE_COMMAND                   # general cmake variable (do not unset)
    #CMAKE_CXX_COMPILER              # general cmake variable (do not unset)
    #CMAKE_CXX_COMPILER_VERSION      # general cmake variable (do not unset)
    CTEST_COST_DATA_FILE
    CTEST_CURL_OPTIONS               # (deprecated in favor of CTEST_TLS_VERIFY)
    CTEST_GIT_INIT_SUBMODULES
    CTEST_GIT_UPDATE_CUSTOM
    CTEST_LABELS_FOR_SUBPROJECTS
    CTEST_P4_CLIENT
    CTEST_P4_OPTIONS
    CTEST_P4_UPDATE_CUSTOM
    CTEST_P4_UPDATE_OPTIONS
    CTEST_SUBMIT_INACTIVITY_TIMEOUT
    CTEST_SVN_OPTIONS
    CTEST_TEST_LOAD
    CTEST_UPDATE_VERSION_ONLY
    CTEST_USE_LAUNCHERS
    CTEST_TLS_VERIFY
    CTEST_TLS_VERSION
    CUDA_SANITIZER_COMMAND
    CUDA_SANITIZER_COMMAND_OPTIONS
    DEFAULT_CTEST_CONFIGURATION_TYPE # CTest default: Release, or from ENV
    DRMEMORY_COMMAND
    DRMEMORY_COMMAND_OPTIONS
    GIT_UPDATE_OPTIONS
    MEMORYCHECK_COMMAND_OPTIONS
    MEMORYCHECK_SANITIZER_OPTIONS
    MEMORYCHECK_TYPE
    NIGHTLY_START_TIME               # CTest default: "00:00:00 EDT"
    #PROJECT_BINARY_DIR              # general cmake variable (do not unset)
    #PROJECT_SOURCE_DIR              # general cmake variable (do not unset)
    PURIFYCOMMAND
    SUBMIT_URL                       # CTest default: (combination of CTEST_DROP_* vars)
    SVN_UPDATE_OPTIONS
    UPDATE_COMMAND                   # CTest default: (based on UPDATE_TYPE)
    UPDATE_OPTIONS                   # CTest default: (based on UPDATE_TYPE)
    UPDATE_TYPE                      # CTest default: (search for .git, etc)
    VALGRIND_COMMAND
    VALGRIND_COMMAND_OPTIONS
  )

  set(SUBMIT_URL_dependency_vars
    CTEST_DROP_LOCATION
    CTEST_DROP_METHOD
    CTEST_DROP_SITE
    CTEST_DROP_SITE_USER
    CTEST_DROP_SITE_PASWORD
    CTEST_DROP_SITE_MODE
  )

  set(ctest_cached_dart_config_vars
    COVERAGE_COMMAND                 # CTest default: find_program(gcov)
    COVERAGE_EXTRA_FLAGS             # CTest default: "-l"
    CTEST_SUBMIT_RETRY_COUNT         # CTest default: 3
    CTEST_SUBMIT_RETRY_DELAY         # CTest default: 5
    CVSCOMMAND                       # CTest default: find_program(cvs)
    CVS_UPDATE_OPTIONS               # CTest default: "-d -A -P"
    DART_TESTING_TIMEOUT             # CTest default: 1500
    GITCOMMAND                       # CTest default: find_program(git)
    MAKECOMMAND                      # CTest default: build_command()
    MEMORYCHECK_COMMAND              # CTest default: find_program(purify git...)
    MEMORYCHECK_SUPPRESSIONS_FILE    # CTest default: ""
    P4COMMAND                        # CTest default: find_program(p4)
    SITE                             # CTest default: cmake_host_system_information()
    SVNCOMMAND                       # CTest default: find_program(svn)
  )

  foreach(var
      ${ctest_uncached_dart_config_vars}
      ${SUBMIT_URL_dependency_vars})
    unset(${var})
    if(PROJECT_IS_NOT_TOP_LEVEL AND DEFINED CACHE{var})
      message(WARNING
        "${PROJECT_NAME}: init_ctest(${ARGN}): detected CTest module variable \
${var} in cache; it may contaminate ctest config settings in other subprojects")
    endif()
  endforeach()

  ##
  ## Parse parameters and set CTest memcheck vars
  ##

  # memcheck subset of CTest module variables, see:
  #   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#ctest-memcheck-step

  set(options
    MEMCHECK
    MEMCHECK_FAILS_TEST
    MEMCHECK_GENERATES_SUPPRESSIONS
  )
  set(single_value_args
    MEMCHECK_SUPPRESSIONS_FILE
  )
  set(multi_value_args
    MEMCHECK_COMMAND_OPTIONS
  )
  cmake_parse_arguments("_ARG"
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )

  if(_ARG_MEMCHECK_FAILS_TEST OR
      _ARG_MEMCHECK_GENERATES_SUPPRESSIONS OR
      _ARG_MEMCHECK_SUPPRESSIONS_FILE OR
      _ARG_MEMCHECK_COMMAND_OPTIONS)
    set(_ARG_MEMCHECK ON)
  endif()
  if(_ARG_MEMCHECK)
    # CTest module sets cache var MEMORYCHECK_COMMAND by using similar call to
    #   find_program, see:
    #   - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L175
    # Doing so here by default allows for earlier determination of selected
    #   program, and thus the appropriate memcheck options to select
    find_program(memcheck_command
      NAMES purify valgrind boundscheck drmemory cuda-memcheck compute-sanitizer
      PATHS "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Rational Software\\Purify\\Setup;InstallFolder]"
      NO_CACHE
    )
    # TBD could not find manuals for purify, boundscheck, drmemory
    # https://docs.nvidia.com/cuda/archive/11.7.0/cuda-memcheck/index.html#memcheck-tool
    # https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html#command-line-options
    if(NOT memcheck_command MATCHES "^.*/valgrind$")
      message(FATAL_ERROR
        "init_ctest() currently only supports memcheck with valgrind")
    endif()
    # CACHE FORCE to supersede both find_program call in CTest and any prior
    #   cached value
    set(MEMORYCHECK_COMMAND ${memcheck_command} CACHE FILEPATH
      "Path to the memory checking command, used for memory error detection."
      FORCE
    )

    if(_ARG_MEMCHECK_COMMAND_OPTIONS)
      set(memcheck_options ${_ARG_MEMCHECK_COMMAND_OPTIONS})
    else()
      # Default valgrind options not passed if user supplies any of their own, see:
      #   - https://github.com/Kitware/CMake/blob/v3.30.4/Source/CTest/cmCTestMemCheckHandler.cxx#L584
      set(memcheck_options
        "-q" "--tool=memcheck" "--leak-check=yes" "--show-reachable=yes"
        "--num-callers=50"
      )
    endif()
    if(_ARG_MEMCHECK_FAILS_TEST)
      list(APPEND memcheck_options "--error-exitcode=255")
    endif()
    if(_ARG_MEMCHECK_GENERATES_SUPPRESSIONS)
      list(APPEND memcheck_options "--gen-suppressions=all")
    endif()
    # join into CLI-friendly string
    list(JOIN memcheck_options " " MEMORYCHECK_COMMAND_OPTIONS)
    # CACHE FORCE to supersede both CTest setting to default of "" and any
    #   prior cached value
    if(_ARG_MEMCHECK_SUPPRESSIONS_FILE)
      set(MEMORYCHECK_SUPPRESSIONS_FILE "${_ARG_MEMCHECK_SUPPRESSIONS_FILE}"
        CACHE FILEPATH "File that contains suppressions for the memory checker"
        FORCE
      )
    endif()
  endif(_ARG_MEMCHECK)

  set(${PROJECT_NAME}_CTEST_MEMCHECK_ENABLED ${_ARG_MEMCHECK} CACHE BOOL
    "${PROJECT_NAME} ctest custom targets may add `--test-action memcheck`" FORCE)

  ##
  ## CTest module consumes variables to configure DartConfiguration.tcl.in
  ##

  # use modern config file name CTestConfiguration.ini over traditional
  #   DartConfiguration.tcl
  set(CTEST_NEW_FORMAT ON)
  include(CTest)
  # BUILD_TESTING now indicates readiness to add tests

  set_property(GLOBAL PROPERTY ${PROJECT_NAME}_CTEST_INITIALIZED TRUE)

  ##
  ## Restore state of BUILD_TESTING
  ##

  unset(BUILD_TESTING CACHE)
  unset(BUILD_TESTING)
  if(_BUILD_TESTING_cached)
    # Using default docstring from CTest.cmake option(BUILD_TESTING) call, see:
    #   - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/CTest.cmake#L50
    set(BUILD_TESTING ${_BUILD_TESTING_value} CACHE BOOL
      "Build the testing tree.")
  elseif(_BUILD_TESTING_defined)
    set(BUILD_TESTING ${_BUILD_TESTING_value})
  endif()
endfunction()
