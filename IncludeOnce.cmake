# newest feature used: include_guard, v3.10
cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# include_once(module example_definition)
#   many cmake modules do not use include_guard, so this macro checks to see if
#     example variables/functions/macros from that module have been set to
#     prevent redundant inclusions
#
#   module              (string): module name
#   example_definitions (string): variables/functions/macros to test
#
macro(include_once module example_definitions)
  set(include_module NO)
  foreach(definition ${example_definitions})
    if(NOT DEFINED ${definition} AND
        NOT COMMAND ${definition})
      set(include_module YES)
    endif()
  endforeach()
  if(include_module)
    include(${module})
  endif()
endmacro()
