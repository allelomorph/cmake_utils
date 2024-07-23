# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

include_guard(DIRECTORY)

option(SKIP_FIND_BEFORE_FETCH
  "No attempt is made to find packages, instead all are built with FetchContent"
  OFF)

if(NOT COMMAND FetchContent_Declare OR
    NOT COMMAND FetchContent_MakeAvailable
  )
  include(FetchContent)
endif()

# fetch_if_not_found(pkg_name fp_options fc_options)
#   Extends cmake 3.24 integration of find_package into FetchContent to work
#     with lower versions
#   On success, sets ${pkg_name}_FOUND or <lowercase pkg_name>_POPULATED
#
#   pkg_name   (string): package name
#   fp_options (list):   find_package args beyond first
#   fc_options (list):   FetchContent_Declare(ExternalProject_Add) args beyond first
#
# !!! This relies on scripts used by find_package creating INTERFACE library
#   targets with the same names (including namespaces, if any,) as ALIAS targets
#   created by FetchContent
macro(fetch_if_not_found
    pkg_name fp_options fc_options
  )
  if ("${CMAKE_VERSION}" VERSION_GREATER_EQUAL 3.24)
    if(SKIP_FIND_BEFORE_FETCH)
      FetchContent_Declare(${pkg_name} ${fc_options})
    else()
      FetchContent_Declare(${pkg_name} ${fc_options} FIND_PACKAGE_ARGS ${fp_options})
    endif()
    FetchContent_MakeAvailable(${pkg_name})
  else()
    if(NOT SKIP_FIND_BEFORE_FETCH)
      find_package(${pkg_name} ${fp_options})
    endif()
    if(NOT ${pkg_name}_FOUND)
      FetchContent_Declare(${pkg_name} ${fc_options})
      FetchContent_MakeAvailable(${pkg_name})
    endif()
  endif()
endmacro()
