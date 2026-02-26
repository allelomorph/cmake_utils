# newest features used: CMAKE_CURRENT_FUNCTION 3.17
cmake_minimum_required(VERSION 3.17)

include_guard(DIRECTORY)

if(COMMAND target_link_libraries_as_system)
  return()
endif()

# target_link_libraries_as_system()
#   Simliar to native target_link_libraries, but interface includes made as
#     system includes to limit compiler and linter errors.
#
#   Based on example at https://stackoverflow.com/a/52136398
#
#   target    (string): target to link libaries to
#   PRIVATE   (option): use private linkage
#   PUBLIC    (option): use public linkage
#   INTERFACE (option): use interface linkage
#   libs      (list, optional): library targets to link to `target`
#
function(target_link_libraries_as_system target)
  set(options PRIVATE PUBLIC INTERFACE)
  cmake_parse_arguments(TLLS "${options}" "" "" ${ARGN})
  foreach(option ${options})
    if(TLLS_${option})
      if(DEFINED scope)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${ARGV}): "
          "please only choose one of ${options}.")
      endif()
      set(scope ${option})
    endif()
  endforeach()
  set(libs ${TLLS_UNPARSED_ARGUMENTS})

  foreach(lib ${libs})
    if(NOT TARGET ${lib})
      message(WARNING "${CMAKE_CURRENT_FUNCTION}(${ARGV}): "
        "library ${lib} is not a target, and will not affect target ${target} "
        "INCLUDE_DIRECTORIES.")
    else()
      get_target_property(lib_interface_include_dirs
        ${lib} INTERFACE_INCLUDE_DIRECTORIES)
      if(NOT lib_interface_include_dirs)
        message(WARNING "${CMAKE_CURRENT_FUNCTION}(${ARGV}): "
          "${lib} doesn't set INTERFACE_INCLUDE_DIRECTORIES, and will not "
          "affect target ${target} INCLUDE_DIRECTORIES.")
      elseif(NOT DEFINED scope)
        target_include_directories(${target} SYSTEM PRIVATE
          ${lib_interface_include_dirs})
      else()
        target_include_directories(${target} SYSTEM ${scope}
          ${lib_interface_include_dirs})
      endif()
    endif()
    # TBD https://stackoverflow.com/questions/51396608/what-is-default-target-link-libraries-privacy-setting
    if(DEFINED scope)
      target_link_libraries(${target} ${scope} ${lib})
    else()
      target_link_libraries(${target} ${lib})
    endif()
  endforeach()

endfunction(target_link_libraries_as_system)
