# newest feature used: cmake_language(DEFER), v3.19
cmake_minimum_required(VERSION 3.19)

include_guard(DIRECTORY)

# record_variable_state(varname)
#   Records variable's state: value, if defined, and cache status
#
#   varname (string): name of variable to record
#
function(record_variable_state varname)

  if(DEFINED ${varname})
    set(_${varname}_defined ON)
  else()
    set(_${varname}_defined OFF)
  endif()
  if(DEFINED CACHE{${varname}})
    set(_${varname}_cached ON)
  else()
    set(_${varname}_cached OFF)
  endif()
  if(_${varname}_defined OR _${varname}_cached)
    set(_${varname}_value ${${varname}})
  endif()

  set(_${varname}_defined ${_${varname}_defined} CACHE BOOL
    "internal record_variable_state variable"
  )
  set(_${varname}_cached ${_${varname}_cached} CACHE BOOL
    "internal record_variable_state variable"
  )
  set(_${varname}_value ${_${varname}_value} CACHE STRING
    "internal record_variable_state variable"
  )
  set(_${varname}_state_recorded ${CMAKE_CURRENT_LIST_FILE} CACHE STRING
    "internal record_variable_state variable"
  )

  # cleanup in case restore_variable_state(${varname}) is never called in
  #   directory scope
  cmake_language(DEFER CALL unset _${varname}_state_recorded CACHE)
  cmake_language(DEFER CALL unset _${varname}_defined CACHE)
  cmake_language(DEFER CALL unset _${varname}_cached CACHE)
  cmake_language(DEFER CALL unset _${varname}_value CACHE)

endfunction()

# restore_variable_state(varname)
#   Restores variable's state from last call to record_variable_state in same
#     script/listfile: value, if defined, and cache status
#
#   varname (string): name of variable to restore
#   DOCSTRING (string, optional): docstring to provide when recaching variable
#
function(restore_variable_state varname)

  if(NOT DEFINED CACHE{_${varname}_state_recorded} OR
      NOT ${_${varname}_state_recorded} STREQUAL ${CMAKE_CURRENT_LIST_FILE})
    message(FATAL_ERROR
      "no matching prior call to record_variable_state(${varname}) made in \
same script/listfile")
  endif()

  set(options)
  set(single_value_args
    DOCSTRING
  )
  set(multi_value_args)
  cmake_parse_arguments("_ARGS"
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )
  # TBD Is there really no way to get a docstring from a CACHE var unless
  #   already written to CMakeCache.txt in a previous config step?
  if(DEFINED _ARGS_DOCSTRING)
    set(docstring ${_ARGS_DOCSTRING})
  else()
    set(docstring "cached value restored by restore_variable_state(${ARGN}) in \
${CMAKE_CURRENT_LIST_FILE}")
  endif()

  unset(${varname} CACHE)
  unset(${varname})
  if(_${varname}_cached)
    set(${varname} ${_${varname}_value} CACHE BOOL "${docstring}")
  elseif(_${varname}_defined)
    set(${varname} ${_${varname}_value})
  endif()

  unset(_${varname}_state_recorded CACHE)
  unset(_${varname}_defined CACHE)
  unset(_${varname}_cached CACHE)
  unset(_${varname}_value CACHE)

endfunction()
