cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# get_all_target_dependencies(target dep_list_var)
#   recursively builds list of target dependencies
#
#   target (string): name of root target
#   dep_list_var (string): variable in parent scope to store dependency list,
#     cannot be "_deps" to avoid shadowing internal implementation variable
#
macro(get_all_target_dependencies target dep_list_var)
  if(NOT TARGET ${target})
    return()
  endif()

  if(${dep_list_var} STREQUAL "_deps")
    message(FATAL_ERROR
      "get_all_target_dependencies(): dep_list_var cannot be \"_deps\", "
      "a protected internal variable name")
  endif()

  set(_inside_get_all_target_dependencies YES)
  _get_all_target_dependencies_impl(${target} ${dep_list_var})
  unset(_inside_get_all_target_dependencies)
  # TBD list(REMOVE_DUPLICATES ${dep_list_var}) once here after recursion
  #   more efficient than checking if(NOT IN_LIST) for each new dep?
  set(${dep_list_var} ${${dep_list_var}} PARENT_SCOPE)

endmacro(get_all_target_dependencies)

# _get_all_target_dependencies_impl(target dep_list_var)
#   internal implementation of get_all_target_dependencies(), all arguments
#   passed unmodified
#
function(_get_all_target_dependencies_impl target dep_list_var)
  if(NOT _inside_get_all_target_dependencies)
    message(FATAL_ERROR
      "_get_all_target_dependencies_impl(): can only be called as part of "
      "get_all_target_dependencies")
  endif()

  # build set of all dependencies of current target, PUBLIC|PRIVATE|INTERFACE
  get_target_property(link_libs ${target} LINK_LIBRARIES)
  get_target_property(interface_link_libs ${target} INTERFACE_LINK_LIBRARIES)
  unset(_deps)  # unset needed due to recursive calls
  if(interface_link_libs)
    list(APPEND _deps ${interface_link_libs})
  endif()
  if(link_libs)
    list(APPEND _deps ${link_libs})
  endif()

  # combine current target dependency set with root target set
  foreach(dep ${_deps})
    if(TARGET ${dep} AND NOT ${dep} IN_LIST ${dep_list_var})
      list(APPEND ${dep_list_var} ${dep})
      _get_all_target_dependencies_impl(${dep} ${dep_list_var})
    endif()
  endforeach()
  set(${dep_list_var} ${${dep_list_var}} PARENT_SCOPE)

endfunction(_get_all_target_dependencies_impl)
