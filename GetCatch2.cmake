# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(Catch2_FOUND OR catch2_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

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

# See https://packages.ubuntu.com/search?keywords=catch2 for package versions
#
# Relevant Catch2 releases:
# - release matching Ubuntu 22.04 LTS package:
#   2.13.8  216713a4066b79d9803d374f261ccb30c0fb451f tag "v2.13.8"
# - release matching Ubuntu 23.10 package:
#   2.13.10 182c910b4b63ff587a3440e08f84f70497e49a81 tag "v2.13.10"
# - release matching Ubuntu 24.04 LTS package:
#   3.4.0   6e79e682b726f524310d55dec8ddac4e9c52fb5f tag "v3.4.0"
set(CATCH_DEFAULT_VERSION "3.4.0")
set(FP_OPTIONS
  ${CATCH_DEFAULT_VERSION}
  # cmake (through v3.30 at least) does not supply FindCatch2.cmake, and Catch2
  #   creates its own config file, see:
  #   - https://github.com/catchorg/Catch2/blob/v2.13.10/CMakeLists.txt#L194
  #   - https://github.com/catchorg/Catch2/blob/v3.4.0/CMakeLists.txt#L128
  CONFIG
)
set(FC_OPTIONS
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        "v${CATCH_DEFAULT_VERSION}"
)
fetch_if_not_found(Catch2 "${FP_OPTIONS}" "${FC_OPTIONS}")

# _CATCH_VERSION_MAJOR intended to be set as compile definition for test targets,
#   this allows for selective includes to accommodate differences in v2 and v3
#   (leading underscore to prevent shadowing CATCH_VERSION_MAJOR, which may be
#   defined by Catch header inclusions)
if(DEFINED CATCH_VERSION_MAJOR)
  set(_CATCH_VERSION_MAJOR "${CATCH_VERSION_MAJOR}")
else()
  string(REGEX REPLACE
    "^([0-9]+)\.[0-9]+\.[0-9]+$" "\\1"
    _CATCH_VERSION_MAJOR "${CATCH_DEFAULT_VERSION}")
endif()
if(NOT _CATCH_VERSION_MAJOR)
  message(FATAL_ERROR "Could not determine Catch2 required major version")
endif()
unset(CATCH_DEFAULT_VERSION)

# adding path to Catch.cmake to allow `include(Catch)`, see above links on
#   cmake integration
if(DEFINED catch2_SOURCE_DIR)      # catch2_POPULATED
  set(CATCH_SOURCE_DIR "${catch2_SOURCE_DIR}")
elseif(DEFINED Catch2_SOURCE_DIR)  # Catch2_FOUND
  set(CATCH_SOURCE_DIR "${Catch2_SOURCE_DIR}")
else()
  message(FATAL_ERROR "Could not find Catch2 source directory")
endif()
if(_CATCH_VERSION_MAJOR EQUAL 2)
  list(APPEND CMAKE_MODULE_PATH "${CATCH_SOURCE_DIR}/contrib")
else()
  list(APPEND CMAKE_MODULE_PATH "${CATCH_SOURCE_DIR}/extras")
endif()
unset(CATCH_SOURCE_DIR)
