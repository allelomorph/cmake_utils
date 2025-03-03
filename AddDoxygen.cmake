# newest features used: cmake_path v3.20
cmake_minimum_required(VERSION 3.20)

include_guard(DIRECTORY)

if(COMMAND add_doxygen)
  return()
endif()

if(NOT COMMAND get_all_subdirectories)
  include(GetAllSubdirectories)
endif()

if(NOT COMMAND FetchContent_Declare OR
    NOT COMMAND FetchContent_MakeAvailable)
  include(FetchContent)
endif()

find_package(Doxygen)

find_program(GRAPHVIZ_DOT_BINARY
  dot
)

if(NOT doxygen-awesome-css_POPULATED)
  FetchContent_Declare(doxygen-awesome-css
    GIT_REPOSITORY
      https://github.com/jothepro/doxygen-awesome-css.git
    GIT_TAG
      v2.3.4
  )
  FetchContent_MakeAvailable(doxygen-awesome-css)
endif()

# define_property calls should be idempotent
define_property(DIRECTORY PROPERTY
  DOCS_TARGET
  BRIEF_DOCS "string containing name of target to build to automatically \
generate documentation for source in this directory "
)

# add_doxygen(input_dir)
#   Sets up Doxygen automated documentation generation for a given source
#     directory, see:
#     - https://github.com/catchorg/Catch2/blob/v3.4.0/docs/cmake-integration.md
#
#   input_dir   (string): source dir for which to generate documentation
#   UNSTYLED    (bool, optional): toggles use of plain Doxygen HTML/CSS
#   OUTPUT_DIR  (string, optional): destination directory for Doxygen output,
#                 will auto-generate a target name if none is provided
#   DOCS_TARGET (string, optional): name of target to build to run the
#                 documentation generation, will also be auto-generated if
#                 not provided
#
function(add_doxygen input_dir)

  if (NOT DOXYGEN_FOUND)
    message(WARNING "add_doxygen(${input_dir} ${ARGN}): cannot generate \
documentation without doxygen package installed")
    return()
  endif()

  # see: https://www.doxygen.nl/manual/markdown.html
  if(DOXYGEN_VERSION VERSION_LESS "1.8.0")
    message(WARNING "add_doxygen(${input_dir} ${ARGN}): found Doxygen \
v${DOXYGEN_VERSION}, 1.8.0+ required for markdown support")
  endif()

  ##
  ## parse and validate required parameter
  ##

  # make input directory path absolute
  cmake_path(SET input_path NORMALIZE ${input_dir})
  if(NOT IS_ABSOLUTE ${input_path})
    cmake_path(APPEND CMAKE_CURRENT_SOURCE_DIR ${input_path}
      OUTPUT_VARIABLE input_path)
  endif()

  # ensure that input directory path has been added with add_subdirectory()
  get_all_subdirectories(${PROJECT_SOURCE_DIR} project_subdir_paths)
  set(input_path_found FALSE)
  foreach(path ${project_subdir_paths})
    if(input_path MATCHES "^${path}$")
      set(input_path_found TRUE)
      break()
    endif()
  endforeach()
  if(NOT input_path_found)
    message(FATAL_ERROR "add_doxygen(${input_dir} ${ARGN}): \"${input_dir}\", \
or \"${input_path}\", is not a directory currently visible to the project")
  endif()

  get_directory_property(docs_target
    DIRECTORY ${input_path}
    DOCS_TARGET
  )
  if(docs_target)
    return()
  endif()

  ##
  ## parse and validate optional parameters
  ##

  set(options
    UNSTYLED
  )
  set(single_value_args
    OUTPUT_DIR
    DOCS_TARGET
  )
  set(multi_value_args
  )
  cmake_parse_arguments("ARGS"
    "${options}" "${single_value_args}" "${multi_value_args}" ${ARGN}
  )

  get_directory_property(binary_path
    DIRECTORY ${input_path}
    BINARY_DIR
  )
  if(DEFINED ARGS_OUTPUT_DIR)
    cmake_path(SET output_path NORMALIZE ${ARGS_OUTPUT_DIR})
    # OUTPUT_DIR can only be outside build if an absolute path to dir
    if(NOT IS_ABSOLUTE ${output_path})
      cmake_path(APPEND binary_path ${output_path}
        OUTPUT_VARIABLE output_path)
    elseif(NOT IS_DIRECTORY ${output_path})
      message(FATAL_ERROR "add_doxygen(${input_dir} ${ARGN}): \
${output_path} is a file, not a directory")
    endif()
  else()
    cmake_path(APPEND binary_path "docs"
      OUTPUT_VARIABLE output_path)
  endif()

  if(DEFINED ARGS_DOCS_TARGET)
    if(TARGET ${ARGS_DOCS_TARGET})
      message(FATAL_ERROR "add_doxygen(${input_dir} ${ARGN}): \
${ARGS_DOCS_TARGET} matches an already existing target, please choose another \
name or run without DOCS_TARGET for automatic target naming")
    else()
      set(target_name ${ARGS_DOCS_TARGET})
    endif()
  else()
    # find shortest unused target name, starting with <dirname>_doc,
    #   then incrementally prepending <parent-dirname>_
    cmake_path(GET input_path FILENAME dirname)
    cmake_path(GET input_path PARENT_PATH parent_path)
    set(target_prefix ${dirname})
    while(TARGET ${target_prefix}_docs)
      list(APPEND attempted_targets ${target_prefix}_docs)
      cmake_path(GET parent_path FILENAME dirname)
      if(${dirname} STREQUAL ${PROJECT_NAME})
        break()
      endif()
      cmake_path(GET parent_path PARENT_PATH parent_path)
      set(target_prefix ${dirname}_${target_prefix})
    endwhile()
    if(TARGET ${target_prefix}_docs)
      message(FATAL_ERROR "add_doxygen(${input_dir} ${ARGN}): all auto-generated \
candidate target names are already taken: ${attempted_targets}")
    else()
      set(target_name ${target_prefix}_docs)
    endif()
  endif()

  ##
  ## set variables to be cosumed by doxygen_add_docs when configuring Doxygen
  ##

  # DOXYGEN_* config cmake variables come in two varieties:
  #   those consumed directly by doxygen_add_docs:
  #     - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/FindDoxygen.cmake#L128
  #   or those that map to Doxygen config options (without the DOXYGEN_ prefix):
  #     - https://www.doxygen.nl/manual/config.html
  #   which doxygen_add_docs uses to configure a Doxyfile when no CONFIG_FILE
  #   param is passed:
  #     - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/FindDoxygen.cmake#L726

  set(DOXYGEN_GENERATE_HTML YES)
  set(DOXYGEN_HTML_OUTPUT   ${output_path})

  if(NOT ${ARGS_UNSTYLED})
    if(doxygen-awesome-css_POPULATED)
      set(DOXYGEN_HTML_EXTRA_STYLESHEET
        ${doxygen-awesome-css_SOURCE_DIR}/doxygen-awesome.css)
      # sidebar
      set(DOXYGEN_GENERATE_TREEVIEW     YES)
      if(GRAPHVIZ_DOT_BINARY)
        # https://jothepro.github.io/doxygen-awesome-css/md_docs_2tricks.html
        set(DOXYGEN_HAVE_DOT            YES)
        set(DOXYGEN_DOT_IMAGE_FORMAT    svg)
        #set(DOXYGEN_DOT_TRANSPARENT    YES) # not doxygen config var as of v1.9.8
      else()
        message(WARNING "add_doxygen(${input_dir} ${ARGN}): cannot generate
documentation graphs without graphviz dot installed")
      endif()
    else()
      message(WARNING "add_doxygen(${input_dir} ${ARGN}): cannot style
documentation without doxygen-awesome-css")
    endif()
  endif()

  ##
  ## config Doxygen and set documentation targets
  ##

  set(all_docs_target_name ${PROJECT_NAME}_docs)
  if(NOT TARGET ${all_docs_target_name})
    add_custom_target(${all_docs_target_name})
  endif()

  doxygen_add_docs(${target_name}
    ${input_path}
    COMMENT "Generate HTML documentation"
  )

  add_dependencies(${all_docs_target_name}
    ${target_name}
  )

  set_property(DIRECTORY ${input_path} PROPERTY
    DOCS_TARGET ${target_name}
  )

  message(STATUS "Added Doxygen target ${target_name} to build docs for \
${input_path} in ${output_path}")

endfunction()
