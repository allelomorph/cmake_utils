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
#   As a consequence, CMake scripts are not documented, only source files.
#
#   This function is somewhat redundant with doxygen_add_docs():
#     - https://cmake.org/cmake/help/v3.31/module/FindDoxygen.html#command:doxygen_add_docs
#     But is an intentional simplification to allow choosing source files via
#     the Doxyfile INPUT variable. Ideally this script should be bundled with a
#     companion Doxyfile.in template.
#
#   inputs   (list): source files and directories for which to generate
#     documentation
#   UNSTYLED (bool, optional): toggles use of plain Doxygen HTML/CSS
#
function(add_doxygen)

  if(TARGET doxygen)
    return()
  endif()

  ##
  ## parse and validate parameters
  ##

  set(_options UNSTYLED)
  set(_single_value_args)
  set(_multi_value_args)
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

  ##
  ## configure Doxyfile to set Doxygen settings
  ##

  # doxygen_add_docs defaults, see:
  #   - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/FindDoxygen.cmake#L899
  set(DOXYGEN_RECURSIVE YES)
  set(DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
  set(DOXYGEN_DOT_MULTI_TARGETS YES)
  set(DOXYGEN_GENERATE_LATEX NO)
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

  # elective options
  set(DOXYGEN_GENERATE_HTML YES)
  set(DOXYGEN_HTML_INDEX_NUM_ENTRIES 1)  # all tree lists start fully collapsed
  set(DOXYGEN_HTML_OUTPUT doxygen_site)

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

  if(EXISTS ${PROJECT_SOURCE_DIR}/Doxyfile.in)
    configure_file(
      ${PROJECT_SOURCE_DIR}/Doxyfile.in
      ${PROJECT_BINARY_DIR}/Doxyfile
      ESCAPE_QUOTES
    )
  elseif(EXISTS ${PROJECT_SOURCE_DIR}/Doxyfile)
    file(COPY_FILE
      ${PROJECT_SOURCE_DIR}/Doxyfile
      ${PROJECT_BINARY_DIR}/Doxyfile
    )
  else()
    message(FATAL_ERROR "add_doxygen(${ARGN}): no Doxyfile.in or Doxyfile \
found in ${PROJECT_SOURCE_DIR}, required for use of doxygen")
  endif()

  ##
  ## Add documentation build target
  ##

  add_custom_target(doxygen
    doxygen Doxyfile
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT
      "Building Doxygen HTML documentation"
    USES_TERMINAL
  )

  message(STATUS "Added Doxygen target doxygen to build HTML docs")

endfunction()
