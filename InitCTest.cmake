# newest feature used: cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

# init_ctest()
#   Assumes configuration of ctest as a dashboard client not by using a
#     CTestConfig or DartConfig script, but by defining variables to be consumed
#     by the CTest module; see:
#     - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
#
#   Implemented as macro wrapping a function due to cmake's (tested with
#     v3.27.4) consistent failure to generate CTestTestfile scripts when
#     enable_testing() was called anywhere but the scope of the project root
#     listfile.
#
#   Note that due to ctest expecting CTestConfiguration.ini/
#     DartConfiguration.tcl in the build root, these settings apply to all
#     subdirectories, see:
#     - https://github.com/Kitware/CMake/blob/v3.27.4/Modules/CTestTargets.cmake#L30
#
#   Sets CTEST_MEMCHECK_ENABLED if ctest is set up to use
#     `--test-action memcheck`.
#   CTest module sets option BUILD_TESTING to toggle testing behavior.
#
#   **currently only supports valgrind for memtest**
#
#   MEMCHECK                        (bool, optional):
#     toggles memcheck on tests
#   MEMCHECK_FAILS_TEST             (bool, optional):
#     toggles memcheck errors failing tests
#   MEMCHECK_GENERATES_SUPPRESSIONS (bool, optional):
#     toggles memcheck generating suppressions file
#   CTEST_MODULE_VARIABLES          (list, optional):
#     allows for passing of variables comsumed by CTest module, in
#       <variable> <value> [<value> ...] format; most are passed directly,
#       but memtest step variables are specially handled:
#       CUDA_SANITIZER_COMMAND
#       CUDA_SANITIZER_COMMAND_OPTIONS
#       DRMEMORY_COMMAND_OPTIONS
#       DRMEMORY_COMMAND
#       MEMORYCHECK_COMMAND
#       MEMORYCHECK_COMMAND_OPTIONS
#       MEMORYCHECK_SANITIZER_OPTIONS
#       MEMORYCHECK_SUPPRESSIONS_FILE
#       MEMORYCHECK_TYPE
#       PURIFYCOMMAND
#       VALGRIND_COMMAND
#       VALGRIND_COMMAND_OPTIONS
#   OVERRIDE_CACHED                 (bool, optional):
#     the CTest module caches some variables, so unless this is true,
#       user-provided values for the following will be ignored:
#       BZRCOMMAND
#       COVERAGE_COMMAND
#       COVERAGE_EXTRA_FLAGS
#       CTEST_SUBMIT_RETRY_COUNT
#       CTEST_SUBMIT_RETRY_DELAY
#       CVSCOMMAND
#       CVS_UPDATE_OPTIONS
#       DART_TESTING_TIMEOUT
#       GITCOMMAND
#       HGCOMMAND
#       MAKECOMMAND
#       MEMORYCHECK_COMMAND
#       MEMORYCHECK_SUPPRESSIONS_FILE
#       P4COMMAND
#       SITE
#       SVNCOMMAND
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

  set(_INIT_CTEST_IMPL_INTERNAL_CALL YES)
  _init_ctest_impl(${ARGN})
  unset(_INIT_CTEST_IMPL_INTERNAL_CALL)

endmacro()

# _init_ctest_impl()
#   Implementation details of init_ctest(), all args are passed in unmodified.
#
function(_init_ctest_impl)

  if(NOT _INIT_CTEST_IMPL_INTERNAL_CALL)
    message(FATAL_ERROR
      "_init_ctest_impl() can only be called as part of init_ctest()")
  endif()

  set(options
    MEMCHECK
    MEMCHECK_FAILS_TEST
    MEMCHECK_GENERATES_SUPPRESSIONS
    OVERRIDE_CACHED
  )
  set(single_value_args
  )
  set(multi_value_args
    CTEST_MODULE_VARIABLES
  )
  cmake_parse_arguments(""
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )

  # second parsing for possible module variables, see:
  #   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#dashboard-client-configuration
  set(option_modvars
  )
  set(single_value_modvars
    BUILDNAME
    CMAKE_COMMAND
    COVERAGE_COMMAND
    CTEST_CDASH_VERSION
    CTEST_DROP_SITE_CDASH
    CTEST_GIT_INIT_SUBMODULES
    CTEST_GIT_UPDATE_CUSTOM
    CTEST_P4_CLIENT
    CTEST_P4_UPDATE_CUSTOM
    CTEST_RESOURCE_SPEC_FILE
    CTEST_SUBMIT_INACTIVITY_TIMEOUT
    CTEST_SUBMIT_RETRY_COUNT
    CTEST_SUBMIT_RETRY_DELAY
    CTEST_TEST_LOAD
    CTEST_TLS_VERIFY
    CTEST_TLS_VERSION
    CTEST_USE_LAUNCHERS
    CUDA_SANITIZER_COMMAND
    CVSCOMMAND
    DART_TESTING_TIMEOUT
    DEFAULT_CTEST_CONFIGURATION_TYPE
    DRMEMORY_COMMAND
    DROP_LOCATION
    DROP_METHOD
    DROP_SITE
    DROP_SITE_PASSWORD
    DROP_SITE_USER
    GITCOMMAND
    MAKECOMMAND
    MEMORYCHECK_COMMAND
    MEMORYCHECK_SUPPRESSIONS_FILE
    MEMORYCHECK_TYPE
    NIGHTLY_START_TIME
    P4COMMAND
    PROJECT_BINARY_DIR
    PROJECT_SOURCE_DIR
    PURIFYCOMMAND
    SITE
    SUBMIT_URL
    SVNCOMMAND
    TRIGGER_SITE
    UPDATE_TYPE
    VALGRIND_COMMAND
  )
  # most multi-value module variables will be converted to space-delimited
  #   strings for CTest module, with the exception of CTEST_LABELS_FOR_SUBPROJECTS,
  #   which can remain a list/semicolon-delimited string
  set(multi_value_modvars
    COVERAGE_EXTRA_FLAGS
    CTEST_CURL_OPTIONS
    CTEST_LABELS_FOR_SUBPROJECTS
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
  )
  cmake_parse_arguments("MV"
    "${option_modvars}" "${single_value_modvars}" "${multi_value_modvars}"
    ${_CTEST_MODULE_VARIABLES}
  )

  # CTest sets some variables to the cache, which will shadow local definitions
  set(cached_modvars
    BZRCOMMAND
    COVERAGE_COMMAND
    COVERAGE_EXTRA_FLAGS
    CTEST_SUBMIT_RETRY_COUNT
    CTEST_SUBMIT_RETRY_DELAY
    CVSCOMMAND
    CVS_UPDATE_OPTIONS
    DART_TESTING_TIMEOUT
    GITCOMMAND
    HGCOMMAND
    MAKECOMMAND
    MEMORYCHECK_COMMAND
    MEMORYCHECK_SUPPRESSIONS_FILE
    P4COMMAND
    SITE
    SVNCOMMAND
  )
  if(NOT _OVERRIDE_CACHED)
    foreach(modvar ${cached_modvars})
      if(MV_${modvar})
        list(APPEND warning_modvars ${modvar})
      endif()
    endforeach()
    list(JOIN warning_modvars ", " warning_modvars)
    message(WARNING "init_ctest(): the following CTest module variables:
${warning_modvars}
may be ignored unless OVERRIDE_CACHED is ON")
  endif()

  # special handling of memcheck step variables, see:
  #   - https://cmake.org/cmake/help/v3.31/manual/ctest.1.html#ctest-memcheck-step
  #
  # TBD currently forcing valgrind use
  if((MV_MEMORYCHECK_TYPE AND
        NOT MV_MEMORYCHECK_TYPE STREQUAL "Valgrind") OR
      MV_CUDA_SANITIZER_COMMAND OR
      MV_CUDA_SANITIZER_COMMAND_OPTIONS OR
      MV_DRMEMORY_COMMAND OR
      MV_DRMEMORY_COMMAND_OPTIONS OR
      MV_MEMORYCHECK_SANITIZER_OPTIONS OR
      MV_PURIFYCOMMAND)
    message(FATAL_ERROR
      "init_ctest() currently only supports memcheck with valgrind")
  endif()
  if(_MEMCHECK_FAILS_TEST OR
      _MEMCHECK_GENERATES_SUPPRESSIONS OR
      MV_MEMORYCHECK_TYPE OR
      MV_MEMORYCHECK_COMMAND OR
      MV_MEMORYCHECK_COMMAND_OPTIONS OR
      MV_MEMORYCHECK_SUPPRESSIONS_FILE OR
      MV_VALGRIND_COMMAND OR
      MV_VALGRIND_COMMAND_OPTIONS
    )
    set(_MEMCHECK ON)
  endif()
  if(_MEMCHECK)
    if(MV_MEMORYCHECK_COMMAND)
      set(memcheck_command ${MV_MEMORYCHECK_COMMAND})
    elseif(MV_VALGRIND_COMMAND)
      set(memcheck_command ${MV_VALGRIND_COMMAND})
    else()
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
    endif()
    # TBD could not find manuals for purify, boundscheck, drmemory
    # https://docs.nvidia.com/cuda/archive/11.7.0/cuda-memcheck/index.html#memcheck-tool
    # https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html#command-line-options
    if(NOT memcheck_command MATCHES "^.*/valgrind$")
      message(FATAL_ERROR
        "init_ctest() currently only supports memcheck with valgrind")
    endif()
    if(_OVERRIDE_CACHED)
      unset(MEMORYCHECK_COMMAND CACHE)
    endif()
    set(MEMORYCHECK_COMMAND ${memcheck_command} CACHE FILEPATH
      "Path to the memory checking command, used for memory error detection."
    )

    if(MV_MEMORYCHECK_COMMAND_OPTIONS)
      set(memcheck_options ${MV_MEMORYCHECK_COMMAND_OPTIONS})
    elseif(MV_VALGRIND_COMMAND_OPTIONS)
      set(memcheck_options ${MV_VALGRIND_COMMAND_OPTIONS})
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
    # join into CLI-friendly string, not a cached module variable
    list(JOIN memcheck_options " " MEMORYCHECK_COMMAND_OPTIONS)

    # MEMORYCHECK_SUPPRESSIONS_FILE cache set to "" in CTest, see:
    #   - https://github.com/Kitware/CMake/blob/v3.30.4/Modules/CTest.cmake#L181
    if(MV_MEMORYCHECK_SUPPRESSIONS_FILE)
      if(_OVERRIDE_CACHED)
        unset(MEMORYCHECK_SUPPRESSIONS_FILE CACHE)
      endif()
      set(MEMORYCHECK_SUPPRESSIONS_FILE "${MV_MEMORYCHECK_SUPPRESSIONS_FILE}"
        CACHE FILEPATH
        "File that contains suppressions for the memory checker")
    endif()

  endif()
  set(CTEST_MEMCHECK_ENABLED ${_MEMCHECK} PARENT_SCOPE)
  # memcheck variables handled above can skip batch processing
  foreach(memcheck_modvar
      MV_CUDA_SANITIZER_COMMAND
      MV_CUDA_SANITIZER_COMMAND_OPTIONS
      MV_DRMEMORY_COMMAND
      MV_DRMEMORY_COMMAND_OPTIONS
      MV_MEMORYCHECK_COMMAND
      MV_MEMORYCHECK_COMMAND_OPTIONS
      MV_MEMORYCHECK_SANITIZER_OPTIONS
      MV_MEMORYCHECK_SUPPRESSIONS_FILE
      MV_MEMORYCHECK_TYPE
      MV_PURIFYCOMMAND
      MV_VALGRIND_COMMAND
      MV_VALGRIND_COMMAND_OPTIONS
    )
    unset(${memcheck_modvar})
  endforeach()

  # batch process variables passed as parameters for consumption by CTest module
  #
  set(_SET_CTEST_MODVAR_INTERNAL_CALL YES)
  foreach(modvar ${single_value_modvars})
    if(MV_${modvar})
      _set_ctest_modvar(${modvar} ${MV_${modvar}})
    endif()
  endforeach()
  foreach(modvar ${multi_value_modvars})
    if(MV_${modvar})
      # most multi-arg module variables are meant to be string of CLI options
      if(NOT modvar STREQUAL "CTEST_LABELS_FOR_SUBPROJECTS")
        list(JOIN MV_${modvar} " " list_as_string)
      else()
        set(list_as_string "${MV_${modvar}}")
      endif()
      _set_ctest_modvar(${modvar} "${list_as_string}")
    endif()
  endforeach()
  unset(_SET_CTEST_MODVAR_INTERNAL_CALL)

  # CTest module consumes variables
  #
  # use modern config file name CTestConfiguration.ini over traditional
  #   DartConfiguration.tcl
  set(CTEST_NEW_FORMAT ON)
  include(CTest)
  # BUILD_TESTING now indicates readiness to add tests

endfunction()

# _set_ctest_modvar(modvar value)
#   Implementation detail of _init_ctest_impl(), conditionally sets CTest module
#     variables
#
macro(_set_ctest_modvar modvar value)

  if(NOT _SET_CTEST_MODVAR_INTERNAL_CALL)
    message(FATAL_ERROR
      "_set_ctest_modvar() can only be called as part of init_ctest()")
  endif()

  if("${modvar}" IN_LIST cached_modvars)
    if(_OVERRIDE_CACHED)
      unset(${modvar} CACHE)
    endif()
    if("${modvar}" MATCHES "^.*COMMAND$")
      set(type FILEPATH)
    else()
      set(type STRING)
    endif()
    set(${modvar} ${value} CACHE ${type}
      "cached to override CTest module caching of same variable")
  else()
    set(${modvar} ${value})
  endif()

endmacro()
