# TBD re-evaluate supported versions
cmake_minimum_required(VERSION 3.16)

include_guard(DIRECTORY)

# set_strict_compile_options(target)
#   sets least error-tolerant options for a target, based on complier in use
#
#   target (string): target to modify
#
macro(set_strict_compile_options target)
  if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(${target} PRIVATE
      /W4 /bigobj
      )
  endif()

  if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(${target} PRIVATE
      -Wall -Wextra -Wpedantic
      )
  endif()

  if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(${target} PRIVATE
      -Wall -Wextra -Wpedantic -Werror
      )
  endif()
endmacro()
