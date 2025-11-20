# newest features used: cmake_path v3.20
cmake_minimum_required(VERSION 3.20)

include_guard(DIRECTORY)

if(COMMAND add_doxygen)
  return()
endif()

if(NOT COMMAND FetchContent_Declare OR
    NOT COMMAND FetchContent_MakeAvailable)
  include(FetchContent)
endif()

if(NOT DOXYGEN_FOUND)
  # Note: cmake find module does not seem to test Doxygen_FIND_REQUIRED_dot, see:
  #  - https://cmake.org/cmake/help/v3.28/command/find_package.html#package-file-interface-variables
  #  - https://github.com/Kitware/CMake/blob/v3.28.0/Modules/FindDoxygen.cmake
  #  but does define:
  #   - DOXYGEN_DOT_EXECUTABLE (deprecated, use target Doxygen::dot instead)
  #   - DOXYGEN_DOT_FOUND (deprecated)
  find_package(Doxygen REQUIRED
    COMPONENTS dot)
  # TBD Should we delete ${PROJECT_BINARY_DIR}/CMakeDoxyfile.in and
  #   ${PROJECT_BINARY_DIR}/CMakeDoxygenDefaults.cmake?
endif()

if(NOT doxygen-awesome-css_POPULATED)
  FetchContent_Declare(doxygen-awesome-css
    GIT_REPOSITORY
      https://github.com/jothepro/doxygen-awesome-css.git
    GIT_TAG
      v2.3.4
  )
  FetchContent_MakeAvailable(doxygen-awesome-css)
endif()

if(NOT DOXYGEN_FOUND)
  message(FATAL_ERROR
    "Doxygen not found; required to build HTML documentation")
endif()

# see: https://www.doxygen.nl/manual/markdown.html
if(DOXYGEN_VERSION VERSION_LESS "1.8.0")
  message(WARNING
    "found Doxygen v${DOXYGEN_VERSION}, 1.8.0+ required for markdown support")
endif()

# add_doxygen()
#   Sets up Doxygen automated documentation generation for the project,
#     accesible via the `doxygen` target.
#
#   Deliberately skips popular Breathe -> Sphinx ReadTheDocs toolchain to
#     avoid all the additional dependencies:
#     - system: python3, python3-pip
#     - pip: breathe, GitPython, Sphinx, sphinxcontrib-moderncmakedomain,
#         sphinx-sitemap, sphinx-rtd-theme
#   As a consequence, CMake script documentation is not supported, only source
#     files.
#
#   Note: this function is redundant with doxygen_add_docs() provided by cmake:
#     - https://cmake.org/cmake/help/v3.31/module/FindDoxygen.html#command:doxygen_add_docs
#     but is intentionally stripped down to:
#       - focus on commonly used config variables
#       - encapsulate setup with doxygen-awesome-css
#     at the cost of:
#       - more Doxygen option flexibility
#       - per-target documentation settings (can only run once per project)
#
#   inputs   (list): source files and directories for which to generate
#     documentation
#   EXCLUDE (list, optional): source files and directories to exclude from inputs
#   UNSTYLED (bool, optional): toggles use of default Doxygen CSS
#   EXTRACT_PRIVATE (bool, optional): toggles documentation of private class members
#
function(add_doxygen)

  # TBD namespace target ${PROJECT_NAME}_doxygen or ${PROJECT_NAME}::doxygen to
  #   prevent clashes if used with FetchContent?
  if(TARGET doxygen)
    message(WARNING "add_doxygen() may only run once per project")
    return()
  endif()

  ##
  ## parse and validate parameters
  ##

  set(_options UNSTYLED EXTRACT_PRIVATE)
  set(_single_value_args)
  set(_multi_value_args EXCLUDE)
  cmake_parse_arguments("ARGS"
    "${_options}" "${_single_value_args}" "${_multi_value_args}" ${ARGN}
  )
  set(inputs ${ARGS_UNPARSED_ARGUMENTS})
  list(REMOVE_DUPLICATES inputs)
  if(NOT DEFINED DOXYGEN_INPUT)
    set(DOXYGEN_INPUT ${inputs})
  else()
    list(APPEND DOXYGEN_INPUT ${inputs})
    list(REMOVE_DUPLICATES DOXYGEN_INPUT)
  endif()
  set(DOXYGEN_EXCLUDE ${ARGS_EXCLUDE})
  list(REMOVE_DUPLICATES DOXYGEN_EXCLUDE)
  list(JOIN DOXYGEN_EXCLUDE " " DOXYGEN_EXCLUDE)

  ##
  ## configure Doxyfile to set Doxygen settings
  ##

  # doxygen_add_docs defaults, see:
  #   - https://github.com/Kitware/CMake/blob/v3.28.0/Modules/FindDoxygen.cmake#L899
  if(NOT DEFINED DOXYGEN_PROJECT_NAME)
    set(DOXYGEN_PROJECT_NAME "${PROJECT_NAME}")
  endif()
  if(NOT DEFINED DOXYGEN_PROJECT_NUMBER)
    set(DOXYGEN_PROJECT_NUMBER ${PROJECT_VERSION})
  endif()
  if(NOT DEFINED DOXYGEN_PROJECT_BRIEF)
    set(DOXYGEN_PROJECT_BRIEF "${PROJECT_DESCRIPTION}")
  endif()
  set(DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
  if(ARGS_EXTRACT_PRIVATE)
    set(DOXYGEN_EXTRACT_PRIVATE YES)
  else()
    set(DOXYGEN_EXTRACT_PRIVATE NO)
  endif()
  set(DOXYGEN_RECURSIVE YES)
  list(APPEND DOXYGEN_EXCLUDE_PATTERNS
    "*/.git/*"
    "*/.svn/*"
    "*/.hg/*"
    "*/CMakeFiles/*"
    "*/_CPack_Packages/*"
    "DartConfiguration.tcl"
    "CTestConfiguration.ini"
    "CMakeLists.txt"
    "CMakeCache.txt"
  )
  list(JOIN DOXYGEN_EXCLUDE_PATTERNS " " DOXYGEN_EXCLUDE_PATTERNS)
  set(DOXYGEN_GENERATE_LATEX NO)
  set(DOXYGEN_DOT_MULTI_TARGETS YES)

  # elective options
  set(DOXYGEN_EXCLUDE_SYMLINKS NO)       # Doxygen default
  set(DOXYGEN_GENERATE_HTML YES)         # Doxygen default, needed for most other HTML_* options
  set(DOXYGEN_HTML_INDEX_NUM_ENTRIES 1)  # all tree lists start fully collapsed
  set(DOXYGEN_HTML_OUTPUT doxygen_site)  # HTML output directory

  if(NOT ${ARGS_UNSTYLED})
    if(doxygen-awesome-css_POPULATED)
      set(DOXYGEN_HTML_EXTRA_STYLESHEET
        ${doxygen-awesome-css_SOURCE_DIR}/doxygen-awesome.css)
      set(DOXYGEN_GENERATE_TREEVIEW     YES) # sidebar
      # Not using deprecated DOXYGEN_HAVE_DOT, see above note on FindDoxygen.cmake
      if(TARGET Doxygen::dot)
        # Settings from:
        #   - https://jothepro.github.io/doxygen-awesome-css/md_docs_2tricks.html
        set(DOXYGEN_HAVE_DOT            YES)
        set(DOXYGEN_DOT_IMAGE_FORMAT    svg)
        #set(DOXYGEN_DOT_TRANSPARENT    YES) # not doxygen config var as of v1.9.8
      else()
        message(WARNING "add_doxygen(${ARGN}): cannot generate documentation "
          "graphs without Graphviz dot installed")
      endif()
    else()
      message(WARNING "add_doxygen(${ARGN}): cannot style documentation without "
        "doxygen-awesome-css")
    endif()
  endif()

  if(EXISTS ${PROJECT_SOURCE_DIR}/Doxyfile)
    file(COPY_FILE
      ${PROJECT_SOURCE_DIR}/Doxyfile
      ${PROJECT_BINARY_DIR}/Doxyfile
    )
  elseif(EXISTS ${PROJECT_SOURCE_DIR}/Doxyfile.in)
    configure_file(
      ${PROJECT_SOURCE_DIR}/Doxyfile.in
      ${PROJECT_BINARY_DIR}/Doxyfile
      @ONLY ESCAPE_QUOTES
    )
  else()
    # Ignoring CMakeDoxyfile.in generated by FindDoxygen.cmake
    file(WRITE ${PROJECT_BINARY_DIR}/Doxyfile.in [[
# Doxyfile 1.9.8
# https://www.doxygen.nl/manual/config.html

#---------------------------------------------------------------------------
# Project related configuration options
#---------------------------------------------------------------------------
PROJECT_NAME           = "@DOXYGEN_PROJECT_NAME@"
PROJECT_NUMBER         = @DOXYGEN_PROJECT_VERSION@
PROJECT_BRIEF          = "@DOXYGEN_PROJECT_BRIEF@"
OUTPUT_DIRECTORY       = @DOXYGEN_OUTPUT_DIRECTORY@

#---------------------------------------------------------------------------
# Build related configuration options
#---------------------------------------------------------------------------
EXTRACT_PRIVATE        = @DOXYGEN_EXTRACT_PRIVATE@

#---------------------------------------------------------------------------
# Configuration options related to the input files
#---------------------------------------------------------------------------
INPUT                  = @DOXYGEN_INPUT@
RECURSIVE              = @DOXYGEN_RECURSIVE@
EXCLUDE                = @DOXYGEN_EXCLUDE@
EXCLUDE_SYMLINKS       = @DOXYGEN_EXCLUDE_SYMLINKS@
EXCLUDE_PATTERNS       = @DOXYGEN_EXCLUDE_PATTERNS@

#---------------------------------------------------------------------------
# Configuration options related to the HTML output
#---------------------------------------------------------------------------
GENERATE_HTML          = @DOXYGEN_GENERATE_HTML@
HTML_OUTPUT            = @DOXYGEN_HTML_OUTPUT@
HTML_STYLESHEET        = @DOXYGEN_STYLESHEET@
HTML_EXTRA_STYLESHEET  = @DOXYGEN_HTML_EXTRA_STYLESHEET@
HTML_INDEX_NUM_ENTRIES = @DOXYGEN_HTML_INDEX_NUM_ENTRIES@
GENERATE_TREEVIEW      = @DOXYGEN_GENERATE_TREEVIEW@

#---------------------------------------------------------------------------
# Configuration options related to the LaTeX output
#---------------------------------------------------------------------------
GENERATE_LATEX         = @DOXYGEN_GENERATE_LATEX@

#---------------------------------------------------------------------------
# Configuration options related to diagram generator tools
#---------------------------------------------------------------------------
HAVE_DOT               = @DOXYGEN_HAVE_DOT@
DOT_IMAGE_FORMAT       = @DOXYGEN_DOT_IMAGE_FORMAT@
DOT_MULTI_TARGETS      = @DOXYGEN_DOT_MULTI_TARGETS@
]])
    configure_file(
      ${PROJECT_BINARY_DIR}/Doxyfile.in
      ${PROJECT_BINARY_DIR}/Doxyfile
      @ONLY ESCAPE_QUOTES
    )
  endif()

  ##
  ## Add documentation build target
  ##

  add_custom_target(doxygen
    doxygen Doxyfile
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Building Doxygen HTML documentation"
    USES_TERMINAL
  )
  message(STATUS "Added Doxygen target doxygen to build HTML docs")

endfunction()
