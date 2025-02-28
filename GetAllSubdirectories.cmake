cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

if(COMAMND get_all_subdirectories)
  return()
endif()

# (get_all_subdirectories root_dir dir_list_var)
#   recursively builds list of all of a directory's subdirectories currently
#     visible to the project after add_subdirectory() calls
#
#   root_dir (string): name of root directory
#   dir_list_var (string): variable in parent scope to store subdirectory list
#
macro(get_all_subdirectories root_dir dir_list_var)

  unset(${dir_list_var})
  set(_inside_get_all_subdirectories YES)
  _get_all_subdirectories_impl(${root_dir} ${dir_list_var})
  unset(_inside_get_all_subdirectories)

endmacro(get_all_subdirectories)

# _get_all_subdirectories_impl(target dir_list_var)
#   internal implementation of get_all_subdirectories(), all arguments
#   passed unmodified
#
function(_get_all_subdirectories_impl curr_dir dir_list_var)

  if(NOT _inside_get_all_subdirectories)
    message(FATAL_ERROR
      "_get_all_subdirectories_impl(): can only be called as part of "
      "get_all_subdirectories")
  endif()

  get_directory_property(subdirs DIRECTORY ${curr_dir} SUBDIRECTORIES)

  # combine current subdirectory set with root directory set
  foreach(dir ${subdirs})
    if(IS_DIRECTORY ${dir})
      # As each child path will be absolute, there should no need to filter
      #   out duplicates
      list(APPEND ${dir_list_var} ${dir})
      _get_all_subdirectories_impl(${dir} ${dir_list_var})
    endif()
  endforeach()
  set(${dir_list_var} ${${dir_list_var}} PARENT_SCOPE)

endfunction(_get_all_subdirectories_impl)
