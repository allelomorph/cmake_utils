# newest features: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(Catch2_FOUND OR catch2_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

include(SetDefaultCatch2Version)

# Using Catch2 v2.x:
# - supports C++11+
# - building Catch2::Catch2WithMain target (static lib) requires setting
#     CATCH_BUILD_STATIC_LIBRARY ON (must be CACHE (BOOL|STATIC) due to
#     CMP0077)
# - designed as a single-header library, include path is simple:
#     <catch2/catch.hpp>
# - test integration script Catch.cmake in `contrib` dir, see:
#   - https://github.com/catchorg/Catch2/blob/v2.13.10/docs/cmake-integration.md
#
# Using Catch2 v3.x:
# - supports C++14+
# - Catch2::Catch2WithMain available by default
# - more flexibility in per-feature include pathing, eg:
#     <catch2/catch_all.hpp>  (could still make a single include)
#       or
#     <catch2/catch_test_macros.hpp>  (basic use of TEST_CASE, SECTION, REQUIRES)
#     <catch2/...>  (selectively include from catch2/ based on features used)
# - test integration script Catch.cmake in `extras` dir, see:
#   - https://github.com/catchorg/Catch2/blob/v3.4.0/docs/cmake-integration.md

# earliest release to use multi-header implementation:
# 3.0.1 605a34765aa5d5ecbf476b4598a862ada971b0cc
# earliest release with robust catch_discover_tests:
set(CATCH_MINIMUM_VERSION "3.4.0")  # 6e79e682b726f524310d55dec8ddac4e9c52fb5f
# latest release at last script update
#   - also introduces cmake support of skipped tests via SKIP_RETURN_CODE, see:
#     - https://github.com/catchorg/Catch2/issues/2873
set(CATCH_CURRENT_VERSION "3.7.1")  # fa43b77429ba76c462b1898d6cd2f2d7a9416b14

if(NOT CATCH2_DEFAULT_VERSION OR
    "${CATCH2_DEFAULT_VERSION}" VERSION_LESS "${CATCH_MINIMUM_VERSION}")
  set(CATCH_TARGET_VERSION "${CATCH_MINIMUM_VERSION}")
else()
  set(CATCH_TARGET_VERSION "${CATCH2_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # Any newer version of the same major should be accepted, see:
  #   - https://github.com/catchorg/Catch2/blob/v2.13.10/CMakeLists.txt#L178
  #   - https://github.com/catchorg/Catch2/blob/v3.4.0/CMakeLists.txt#L123
  ${CATCH_MINIMUM_VERSION}
  # cmake (through v3.30 at least) does not supply FindCatch2.cmake, and Catch2
  #   creates its own config file, see:
  #   - https://github.com/catchorg/Catch2/blob/v2.13.10/CMakeLists.txt#L194
  #   - https://github.com/catchorg/Catch2/blob/v3.4.0/CMakeLists.txt#L128
  CONFIG
)
set(FC_OPTIONS
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        "v${CATCH_TARGET_VERSION}"
    GIT_SHALLOW
)
fetch_if_not_found(Catch2 "${FP_OPTIONS}" "${FC_OPTIONS}")

# find_package success in config mode should set <PackageName>_VERSION*, see:
#   - https://cmake.org/cmake/help/v3.30/command/find_package.html#version-selection
# If fetched instead similar catch2_* variables will not be set by FetchContent, see:
#   - https://cmake.org/cmake/help/v3.30/module/FetchContent.html#command:fetchcontent_populate
if(catch2_POPULATED)
  set(Catch2_VERSION "${CATCH_TARGET_VERSION}")
  string(REGEX REPLACE
    "^([0-9]+)\.[0-9]+\.[0-9]+$" "\\1"
    Catch2_VERSION_MAJOR "${Catch2_VERSION}")
  string(REGEX REPLACE
    "^[0-9]+\.([0-9]+)\.[0-9]+$" "\\1"
    Catch2_VERSION_MINOR "${Catch2_VERSION}")
  string(REGEX REPLACE
    "^[0-9]+\.[0-9]+\.([0-9]+)$" "\\1"
    Catch2_VERSION_PATCH "${Catch2_VERSION}")
  set(Catch2_VERSION_COUNT 3)
endif()

# adding path to Catch.cmake to allow `include(Catch)`, see above links on
#   cmake integration
if(DEFINED catch2_SOURCE_DIR)      # catch2_POPULATED
  set(CATCH_SOURCE_DIR "${catch2_SOURCE_DIR}")
elseif(DEFINED Catch2_SOURCE_DIR)  # Catch2_FOUND
  set(CATCH_SOURCE_DIR "${Catch2_SOURCE_DIR}")
else()
  message(FATAL_ERROR "Could not find Catch2 source directory")
endif()
if(${Catch2_VERSION_MAJOR} EQUAL 2)
  list(APPEND CMAKE_MODULE_PATH "${CATCH_SOURCE_DIR}/contrib")
else()
  list(APPEND CMAKE_MODULE_PATH "${CATCH_SOURCE_DIR}/extras")
endif()
unset(CATCH_SOURCE_DIR)
