# newest features used: TBD
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

if(COMMAND add_coverage_instrumentation AND
    COMMAND add_coverage_report)
  return()
endif()

if(NOT COMMAND get_all_target_dependencies)
  include(GetAllTargetDependencies)
endif()

find_program(GCOV_BINARY
  gcov
  REQUIRED
)
find_program(LCOV_BINARY
  lcov
  REQUIRED
)
find_program(GENHTML_BINARY
  genhtml
  REQUIRED
)

# define_property calls should be idempotent
define_property(TARGET PROPERTY
  COVERAGE_INSTRUMENTATION
  BRIEF_DOCS "boolean indicating code coverage instrumentation has been added \
to target"
)

define_property(TARGET PROPERTY
  COVERAGE_REPORT
  BRIEF_DOCS "boolean indicating code coverage report generation target has \
been added for target"
)

# add_coverage_instrumentation(target)
#   When building in Debug mode, turns on coverage instrumentation for a
#     given target, generating files for use in later generating coverage
#     reports:
#     - .gcno, or GNU Coverage Notes
#     - .gcda, or GNU Coverage Data
#   Should support both GCC and Clang, provided their respective report
#     generation tools (gcov and llvm-cov) are available.
#
#   target           (string): target to which to add instrumentation
#
function(add_coverage_instrumentation target)
  if (NOT TARGET ${target})
    return()
  endif()

  if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "add_coverage_instrumentation(${target}): coverage only \
supported when compiling in Debug mode")
    return()
  endif()

  get_target_property(coverage_instrumentation ${target}
    COVERAGE_INSTRUMENTATION
  )
  if(coverage_instrumentation)
    return()
  endif()

  # clang should match gcc support of --coverage flags (enabling -fprofile-arcs
  #   and -ftest-coverage)
  target_compile_options(${target} PRIVATE
    --coverage
  )
  target_link_options(${target} PUBLIC
    --coverage
  )
  # .gcno files are updated at every recompilation, but .gcda files are not,
  #   potentially causing a mismatch that can result in SEGFAULTs, so here
  #   we clean any stale .gcda files
  add_custom_command(TARGET ${target}
    PRE_BUILD COMMAND
    find ${CMAKE_BINARY_DIR} -type f -name '*.gcda' -exec rm {} +
  )

  set_target_properties(${target} PROPERTIES
    COVERAGE_INSTRUMENTATION TRUE
  )

endfunction()

# add_coverage_report(target)
#   Sets up an optional target `${target}_coverage` that generates an HTML
#     code coverage report for the given target. All coverage report targets
#     will also be linked to a catchall `${PROJECT_NAME}_coverage` target.
#
#   target           (string): target for which to generate report
#
function(add_coverage_report target)
  if (NOT TARGET ${target})
    return()
  endif()

  if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(WARNING "add_coverage_report(${target}): coverage only supported when \
compiling in Debug mode")
    return()
  endif()

  get_target_property(coverage_report ${target}
    COVERAGE_REPORT
  )
  if(coverage_report)
    return()
  endif()

  get_target_property(coverage_instrumentation ${target}
    COVERAGE_INSTRUMENTATION
  )
  if(NOT coverage_instrumentation)
    get_all_target_dependencies(${target} ${target}_deps)
    foreach(dep ${${target}_deps})
      get_target_property(coverage_instrumentation ${dep}
        COVERAGE_INSTRUMENTATION
      )
      if(coverage_instrumentation)
        break()
      endif()
    endforeach()
  endif()
  if(NOT coverage_instrumentation)
    message(FATAL_ERROR "add_coverage_report(${target}): coverage report \
generation requires target or at least one dependency to have coverage \
instrumentation")
  endif()

  set(LCOV_BASE_CMD "${LCOV_BINARY}")
  if(CMAKE_C_COMPILER MATCHES "clang" OR CMAKE_CXX_COMPILER MATCHES "clang")
    find_program(LLVM-COV_BINARY
      llvm-cov
    )
    if(NOT LLVM-COV_BINARY)
      message(FATAL_ERROR "add_coverage_report(${target}): coverage report \
generation when compiling with clang requires llvm-cov")
    endif()
    # man lcov(1) -> man geninfo(1): second use of --gcov-tool adds params to
    #   command named in first use, so equivalent to `llvm-cov gcov`
    string(APPEND LCOV_BASE_CMD
      " --gcov-tool ${LLVM-COV_BINARY} --gcov-tool gcov")
  endif()

  if(NOT TARGET ${PROJECT_NAME}_coverage)
    add_custom_target(${PROJECT_NAME}_coverage)
  endif()

  add_custom_target(${target}_coverage
    COMMENT "Running coverage for ${target}..."
    # reset counters
    COMMAND ${LCOV_BASE_CMD} -d . --zerocounters
    # run target executable
    COMMAND $<TARGET_FILE:${target}>
    # collect metrics from current directory and output to file
    COMMAND ${LCOV_BASE_CMD} -d . --capture -o coverage.info
    # filter out coverage on system headers
    COMMAND ${LCOV_BASE_CMD} -r coverage.info '/usr/include/*' -o filtered.info
    # generate HTML report in coverage directory, with legend color
    COMMAND ${GENHTML_BINARY} -o coverage filtered.info --legend
    # cleanup
    COMMAND rm -rf coverage.info filtered.info
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

  add_dependencies(${PROJECT_NAME}_coverage
    ${target}_coverage
  )

  set_target_properties(${target} PROPERTIES
    COVERAGE_REPORT TRUE
  )

endfunction()
