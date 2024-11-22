cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# get_all_target_dependencies(target dep_list_var)
#   recursively builds list of target dependencies
#
#   target (string): name of root target
#   dep_list_var (string): variable in parent scope to store dependency list,
#     cannot be "_deps" to avoid shadowing internal variable
#
function(get_all_target_dependencies target dep_list_var)
  if(NOT TARGET ${target})
    return()
  endif()

  # build set of all dependencies of current target, PUBLIC|PRIVATE|INTERFACE
  get_target_property(link_libs ${target} LINK_LIBRARIES)
  get_target_property(interface_link_libs ${target} INTERFACE_LINK_LIBRARIES)
  unset(_deps)  # unset needed due to recursive calls
  if(interface_link_libs)
    set(_deps ${interface_link_libs})
  endif()
  if(link_libs)
    foreach(lib ${link_libs})
      if(NOT ${lib} IN_LIST _deps)
        list(APPEND _deps ${lib})
      endif()
    endforeach()
  endif()

  # combine current target dependency set with root target set
  foreach(dep ${_deps})
    if(NOT ${dep} IN_LIST ${dep_list_var})
      list(APPEND ${dep_list_var} ${dep})
    endif()
    get_all_target_dependencies(${dep} ${dep_list_var})
  endforeach()
  set(${dep_list_var} ${${dep_list_var}} PARENT_SCOPE)

endfunction(get_all_target_dependencies)
