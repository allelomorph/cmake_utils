# newest features used: PROJECT_IS_TOP_LEVEL v3.21
cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

if(COMMAND add_mkdocs)
  return()
endif()

##
## Check dependencies
##

if(NOT doxide_POPULATED)
  include(GetDoxide)
endif()

find_package(Python3)

find_program(PIP_BINARY
  pip
)

if(PIP_BINARY)
  foreach(pip_pkg mkdocs mkdocs-material)
    execute_process(
      COMMAND pip show ${pip_pkg}
      RESULT_VARIABLE ${pip_pkg}_FOUND
      OUTPUT_QUIET
      ERROR_QUIET
    )
    # bash exit codes are inverse of expected booleans
    if(${pip_pkg}_FOUND)
      set(${pip_pkg}_FOUND FALSE)
    else()
      set(${pip_pkg}_FOUND TRUE)
    endif()
  endforeach()
endif()

if(NOT doxide_POPULATED)
  message(FATAL_ERROR
    "doxide not found; required to build markdown inputs for mkdocs")
endif()

if(NOT Python3_FOUND)
  message(FATAL_ERROR
    "python3 not found; required for use of mkdocs")
endif()

if(NOT PIP_BINARY)
  message(FATAL_ERROR
    "python3 pip not found; required for use of mkdocs")
endif()

if(NOT mkdocs_FOUND)
  message(FATAL_ERROR
    "pip package mkdocs not found; please ensure that you are in the \
correct python environment")
endif()

if(NOT mkdocs-material_FOUND)
  message(FATAL_ERROR
    "pip package mkdocs-material not found; please ensure that you are in the \
correct python environment")
endif()

# add_mkdocs()
#   Sets up MkDocs automated documentation generation for the project,
#     accesible via the `mkdocs` target. Also produces Markdown documentation
#     via the `doxide_md` target.
#
function(add_mkdocs)

  if(TARGET mkdocs)
    return()
  endif()

  ##
  ## Create doxide setup script
  ##

  # doxide v0.9.0 expects file paths in doxide.yaml to be relative to the
  #   directory in which it is run, so in order to run it in the build
  #   directory we need to make the file paths absolute.
  # If we want the doxdie/mkdocs config to update based on changes to the
  #   yaml.in files, we need to config them in an add_custom_command, and
  #   since that limits us to cli calls, we need a script to do the
  #   preparation:
  set(setup_script_text [==[
# newest features used: cmake -E rm v3.17
cmake_minimum_required(VERSION 3.17)

# FetchContent may put the doxide binary in its default designated build dir
#   ${FETCHCONTENT_BASE_DIR}/doxide-build, or choose to follow the install
#   path set by doxide, see:
#   - https://github.com/lawmurray/doxide/blob/v0.9.0/CMakeLists.txt#L65
#   - https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
# TBD CMAKE_SKIP_INSTALL_RULES seems to have no effect on this behavior
if(EXISTS @doxide_BINARY_DIR@/doxide)
  set(doxide_path @doxide_BINARY_DIR@/doxide)
elseif(EXISTS @PROJECT_BINARY_DIR@/@CMAKE_INSTALL_BINDIR@/doxide)
  set(doxide_path @PROJECT_BINARY_DIR@/@CMAKE_INSTALL_BINDIR@/doxide)
else()
  message(FATAL_ERROR "Could not locate doxide executable, expected either \
@doxide_BINARY_DIR@/doxide or @PROJECT_BINARY_DIR@/@CMAKE_INSTALL_BINDIR@/doxide")
endif()

# first init doxide to create any files not supplied by PROJECT_SOURCE_DIR
execute_process(
  # `doxide init` will hang waiting for user confirmation for deletion of
  #    previous files, even when piping in `yes`
  COMMAND @CMAKE_COMMAND@ -E rm -rf docs/ doxide.yaml mkdocs.yaml
  COMMAND ${doxide_path} init
  WORKING_DIRECTORY @PROJECT_BINARY_DIR@
  OUTPUT_QUIET
  COMMAND_ERROR_IS_FATAL ANY
)

# Pre-existing @PROJECT_SOURCE_DIR@/docs intended when topic/nav bar
#   markdown pages not derived from source are part of the documentation.
#   In that case make sure that the mkdocs.yaml has the proper `nav` section:
#   - https://www.mkdocs.org/user-guide/configuration/#nav
#   and that the docs dir contains the subdirectories produced by
#   `doxide init`
if(IS_DIRECTORY @PROJECT_SOURCE_DIR@/docs)
  # already screened for doxide init support files in add_mkdocs()
  file(COPY @PROJECT_SOURCE_DIR@/docs
    DESTINATION @PROJECT_BINARY_DIR@
  )
endif()

# doxide v0.9.0 expects file paths in doxide.yaml to be relative to the
#   directory in which it is run, so in order to run it in the build
#   directory we need to make the file paths absolute.
if(EXISTS @PROJECT_SOURCE_DIR@/doxide.yaml.in)
  # We must define again here any cmake variables that will be consumed by
  #   doxide.yaml.in, as it will be configured at build time
  set(PROJECT_SOURCE_DIR "@PROJECT_SOURCE_DIR@")
  set(PROJECT_NAME "@PROJECT_NAME@")
  set(PROJECT_DESCRIPTION "@PROJECT_DESCRIPTION@")
  configure_file(
    @PROJECT_SOURCE_DIR@/doxide.yaml.in
    @PROJECT_BINARY_DIR@/doxide.yaml
    ESCAPE_QUOTES
  )
elseif(EXISTS @PROJECT_SOURCE_DIR@/doxide.yaml)
  file(COPY_FILE
    @PROJECT_SOURCE_DIR@/doxide.yaml
    @PROJECT_BINARY_DIR@/doxide.yaml
  )
else()
  message(FATAL_ERROR "No doxide.yaml.in or doxide.yaml found in \
@PROJECT_SOURCE_DIR@, required for use of doxide")
endif()

if(EXISTS @PROJECT_SOURCE_DIR@/mkdocs.yaml.in)
  # We must define again here any cmake variables that will be consumed by
  #   mkdocs.yaml.in, as it will be configured at build time
  set(PROJECT_SOURCE_DIR "@PROJECT_SOURCE_DIR@")
  set(PROJECT_NAME "@PROJECT_NAME@")
  set(PROJECT_DESCRIPTION "@PROJECT_DESCRIPTION@")
  execute_process(
    COMMAND git config --get remote.origin.url
    WORKING_DIRECTORY @PROJECT_SOURCE_DIR@
    OUTPUT_VARIABLE git_remote_origin_url
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  if(git_remote_origin_url)
    string(REGEX REPLACE
      "^(.*)\\.git$" "\\1"
      MKDOCS_REPO_URL ${git_remote_origin_url})
    string(REGEX REPLACE
      "^https:\\/\\/(git(hub|lab|kraken)|bitbucket).com\\/(.*)$" "\\3"
      MKDOCS_REPO_NAME ${MKDOCS_REPO_URL})
    string(REGEX REPLACE
      "^https:\\/\\/(git(hub|lab|kraken)|bitbucket).com\\/(.*)$" "\\1"
      MKDOCS_REPO_ICON ${MKDOCS_REPO_URL})
    set(MKDOCS_REPO_ICON "fontawesome/brands/${MKDOCS_REPO_ICON}")
  endif()
  # TBD may only need this option when debugging file tree in browser, remove if
  #   actually serving content online
  set(MKDOCS_USE_DIRECTORY_URLS "false")
  configure_file(
    @PROJECT_SOURCE_DIR@/mkdocs.yaml.in
    @PROJECT_BINARY_DIR@/mkdocs.yaml
    ESCAPE_QUOTES
  )
elseif(EXISTS @PROJECT_SOURCE_DIR@/mkdocs.yaml)
  file(COPY_FILE
    @PROJECT_SOURCE_DIR@/mkdocs.yaml
    @PROJECT_BINARY_DIR@/mkdocs.yaml
  )
else()
  message(FATAL_ERROR "No mkdocs.yaml.in or mkdocs.yaml found in \
@PROJECT_SOURCE_DIR@, required for use of mkdocs")
endif()
]==])
  if(NOT IS_DIRECTORY ${PROJECT_SOURCE_DIR}/cmake)
    file(MAKE_DIRECTORY ${PROJECT_SOURCE_DIR}/cmake)
  endif()
  set(setup_script_name "SetUpDoxideMkDocs.cmake")
  set(setup_script_path ${PROJECT_SOURCE_DIR}/cmake/${setup_script_name})
  file(WRITE ${setup_script_path}.in "${setup_script_text}")
    configure_file(
      ${setup_script_path}.in
      ${setup_script_path}
      @ONLY
    )
  file(REMOVE ${setup_script_path}.in)

  ##
  ## Add documentation build targets
  ##

  file(GLOB_RECURSE setup_dependencies
    ${PROJECT_SOURCE_DIR}/docs/*.md
    ${PROJECT_SOURCE_DIR}/docs/*.markdown
  )
  if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/docs)
    set(doxide_docs_contents
      ${PROJECT_SOURCE_DIR}/docs/javascripts/mathjax.js
      ${PROJECT_SOURCE_DIR}/docs/javascripts/tablesort.js
      ${PROJECT_SOURCE_DIR}/docs/overrides/partials/copyright.html
      ${PROJECT_SOURCE_DIR}/docs/stylesheets/doxide.css
    )
    foreach(path ${doxide_docs_contents})
      if(NOT EXISTS ${path})
        message(FATAL_ERROR "add_mkdocs(): ${PROJECT_SOURCE_DIR}/docs, if \
present, must contain all support files created by `doxide init`; could not \
find ${path}")
      endif()
      list(APPEND setup_dependencies ${path})
    endforeach()
  endif()
  if(EXISTS ${PROJECT_SOURCE_DIR}/doxide.yaml.in)
    list(APPEND setup_dependencies ${PROJECT_SOURCE_DIR}/doxide.yaml.in)
  elseif(EXISTS ${PROJECT_SOURCE_DIR}/doxide.yaml)
    list(APPEND setup_dependencies ${PROJECT_SOURCE_DIR}/doxide.yaml)
  endif()
  if(EXISTS ${PROJECT_SOURCE_DIR}/mkdocs.yaml.in)
    list(APPEND setup_dependencies ${PROJECT_SOURCE_DIR}/mkdocs.yaml.in)
  elseif(EXISTS ${PROJECT_SOURCE_DIR}/mkdocs.yaml)
    list(APPEND setup_dependencies ${PROJECT_SOURCE_DIR}/mkdocs.yaml)
  endif()

  add_custom_command(
    OUTPUT
      ${PROJECT_BINARY_DIR}/docs/javascripts/mathjax.js
      ${PROJECT_BINARY_DIR}/docs/javascripts/tablesort.js
      ${PROJECT_BINARY_DIR}/docs/overrides/partials/copyright.html
      ${PROJECT_BINARY_DIR}/docs/stylesheets/doxide.css
      ${PROJECT_BINARY_DIR}/doxide.yaml
      ${PROJECT_BINARY_DIR}/mkdocs.yaml
    COMMAND
      ${CMAKE_COMMAND} -P ${setup_script_path}
    # TBD when copying in docs/ from PROJECT_SOURCE_DIR, for some reason it is
    #   considered always out of date
    DEPENDS ${setup_dependencies}
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    USES_TERMINAL
    COMMENT "Setting up doxide and mkdocs builds"
  )

  add_custom_target(doxide_md
    doxide build
    DEPENDS
      doxide
      ${PROJECT_BINARY_DIR}/docs/javascripts/mathjax.js
      ${PROJECT_BINARY_DIR}/docs/javascripts/tablesort.js
      ${PROJECT_BINARY_DIR}/docs/overrides/partials/copyright.html
      ${PROJECT_BINARY_DIR}/docs/stylesheets/doxide.css
      ${PROJECT_BINARY_DIR}/doxide.yaml
      ${PROJECT_BINARY_DIR}/mkdocs.yaml
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    USES_TERMINAL
    COMMENT "Building Doxide markdown documentation"
  )

  message(STATUS "Added Doxide target doxide_md to build Markdown docs")

  # TBD --coverage support
  add_custom_target(mkdocs
    mkdocs build --site-dir mkdocs_site
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT
      "Building MkDocs HTML documentation"
    USES_TERMINAL
  )
  add_dependencies(mkdocs doxide_md)

  message(STATUS "Added MkDocs target mkdocs to build HTML docs")

endfunction()
