# newest features used:
#  if(DEFINED CACHE{}) v3.14
#  cmake_parse_args defines <prefix>_KEYWORDS_MISSING_VALUES v3.15
cmake_minimum_required(VERSION 3.15)

include_guard(DIRECTORY)

if(NOT COMMAND get_all_target_dependencies)
  include(GetAllTargetDependencies)
endif()

# setup_integrated_linters()
#   Sets the following options and cache variables, intended for use by
#     integrate_linting():
#     SKIP_ALL_LINTING
#     SKIP_ALL_CLANG_TIDY
#     SKIP_ALL_CPPCHECK
#     SKIP_ALL_CPPLINT
#     SKIP_ALL_IWYU
#     _CMAKE_CLANG_TIDY
#     _CMAKE_CPPCHECK
#     _CMAKE_CPPLINT
#     _CMAKE_INCLUDE_WHAT_YOU_USE
#
#   CMake docs recommend integrating linting by setting linter commands to
#     CMAKE_<lang>_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE, which in
#     turn will set <lang>_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE for
#     every compiled target. In practice, it seems much easier to opt in to
#     linting on a per-target basis, to help prevent unwanted linting of
#     depedencies downloaded with FetchContent, for example.
#   So as an alternative, here we cache the shared prefix for each C/C++ linter
#     command, and allow target-specific options be appended later by
#     integrate_linting().
#
function(setup_integrated_linters)

  option(SKIP_ALL_LINTING
    "skips all per-target integrated linting")
  option(SKIP_ALL_CLANG_TIDY
    "skips all per-target integrated clang-tidy linting")
  option(SKIP_ALL_CPPCHECK
    "skips all per-target integrated cppcheck linting")
  option(SKIP_ALL_CPPLINT
    "skips all per-target integrated cpplint linting")
  option(SKIP_ALL_IWYU
    "skips all per-target integrated include-what-you-use linting")

  if(SKIP_ALL_LINTING)
    return()
  endif()

  # (idempotent)
  define_property(TARGET
integrated_linting    PROPERTY INTEGRATED_LINTING
    BRIEF_DOCS "boolean indicating target linting setup via integrate_linting()"
  )

  # set prefix of clang-tidy command line for all targets
  if(NOT SKIP_ALL_CLANG_TIDY AND
      NOT DEFINED CACHE{_CMAKE_CLANG_TIDY})
    find_program(CLANG_TIDY_BINARY
      clang-tidy
    )
    if(CLANG_TIDY_BINARY)
      # no cmake attempt to find .clang-tidy, as linter will perform its own
      #   search when it runs in targets' source directories
      # clang-tidy errors will always stop the build, see:
      #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L419
      list(APPEND clang_tidy_command
        "${CLANG_TIDY_BINARY}"
      )
      list(APPEND clang_tidy_command
        "--warnings-as-errors=*"
      )
      set(_CMAKE_CLANG_TIDY "${clang_tidy_command}"
        CACHE STRING
        "default clang-tidy C/C++ command line for linting files"
      )
    else()
      message(WARNING "clang-tidy not found, skipping use as linter")
    endif()
  endif()

  # set prefix of cppcheck command line for all targets
  if(NOT SKIP_ALL_CPPCHECK AND
      NOT DEFINED CACHE{_CMAKE_CPPCHECK})
    find_program(CPPCHECK_BINARY
      NAMES cppcheck
    )
    if(CPPCHECK_BINARY)
      # cppcheck by default should not stop the build when reporting errors, see:
      #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L529
      #   (this can be toggled with --error-exitcode)
      list(APPEND cppcheck_command
        "${CPPCHECK_BINARY}"
        # checks not needed for any target source
        "--disable=missingInclude,unusedFunction"
        "--enable=all"
        # end build on cppcheck error
        "--error-exitcode=1"
      )
      if(DEFINED FETCHCONTENT_BASE_DIR)
        list(APPEND cppcheck_command
          # suppress errors from code included from fetched dependencies
          "--suppress=*:*${FETCHCONTENT_BASE_DIR}/*"
        )
      endif()
      set(_CMAKE_CPPCHECK "${cppcheck_command}" CACHE STRING
        "default cppcheck C/C++ command line for linting files")
    else()
      message(WARNING "cppcheck not found, skipping use as linter")
    endif()
  endif()

  # set prefix of cpplint command line for all targets
  if(NOT SKIP_ALL_CPPLINT AND
      NOT DEFINED CACHE{_CMAKE_CPPLINT})
    find_program(CPPLINT_BINARY
      NAMES cpplint
    )
    if(CPPLINT_BINARY)
      # no cmake attempt to find CPPLINT.cfg, as linter will perform its own
      #   search when it runs in targets' source directories
      list(APPEND cpplint_command
        "${CPPLINT_BINARY}"
      )
      # cpplint errors will never stop the build and are only issued as warnings
      #   (plain text, not message(WARNING),) see:
      #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L475
      list(APPEND cpplint_command
        "--filter=-legal,-build/include_subdir"
      )
      set(_CMAKE_CPPLINT "${cpplint_command}" CACHE STRING
        "default cpplint C/C++ command line for linting files")
    else()
      message(WARNING "cpplint not found, skipping use as linter")
    endif()
  endif()

  # set prefix of include-what-you-use command line for all targets
  if(NOT SKIP_ALL_IWYU AND
      NOT DEFINED CACHE{_CMAKE_IWYU})
    find_program(IWYU_BINARY
      NAMES include-what-you-use iwyu
    )
    if(IWYU_BINARY)
      # include-what-you-use errors only issued as warnings (not
      #   message(WARNING)) unless using --error to set exit code, see:
      #   - https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L363
      # -Xiwyu needed before every iwyu option other than --version and --help
      list(APPEND iwyu_command
        "${IWYU_BINARY}"
      )
      set(_CMAKE_IWYU "${iwyu_command}" CACHE STRING
        "default include-what-you-use C/C++ command line for linting files")
    else()
      message(WARNING "include-what-you-use not found, skipping use as linter")
    endif()
  endif()

  # https://cmake.org/cmake/help/v3.30/variable/CMAKE_LINK_WHAT_YOU_USE.html
  # https://cmake.org/cmake/help/v3.30/variable/CMAKE_LINK_WHAT_YOU_USE_CHECK.html
  #set(_CMAKE_LINK_WHAT_YOU_USE ${CMAKE_LINK_WHAT_YOU_USE_CHECK} CACHE STRING
  #  "default C/C++ command line for checking for unused links to targets")

endfunction()

# integrate_linting(target)
#   Uses cached _CMAKE_CLANG_TIDY/CPPCHECK/CPPLINT/IWYU and target properties to
#     set C/CXX_CLANG_TIDY/CPPCHECK/CPPLINT/INCLUDE_WHAT_YOU_USE on a per-target
#     basis, rather than globally with CMAKE_CLANG_TIDY/CPPCHECK/CPPLINT/
#     INCLUDE_WHAT_YOU_USE.
#
#   target           (string): target to set properties
#   SKIP_CLANG_TIDY  (bool, optional): skips clang-tidy, default OFF
#   SKIP_CPPCHECK    (bool, optional): skips cppcheck, default OFF
#   SKIP_CPPLINT     (bool, optional): skips cpplint, default OFF
#   SKIP_IWYU        (bool, optional): skips include-what-you-use, default OFF
#   CLANG_TIDY_ARGS  (list, optional): addtional clang-tidy CLI args
#   CPPCHECK_ARGS    (list, optional): addtional cppcheck CLI args
#   CPPLINT_ARGS     (list, optional): addtional cpplint CLI args
#   IWYU_ARGS        (list, optional): addtional include-what-you-use CLI args
#
function(integrate_linting target)
  if(NOT TARGET "${target}" OR
      SKIP_ALL_LINTING)
    return()
  endif()

  set(options
    SKIP_CLANG_TIDY
    SKIP_CPPCHECK
    SKIP_CPPLINT
    SKIP_IWYU
  )
  set(multi_value_args
    CLANG_TIDY_ARGS
    CPPCHECK_ARGS
    CPPLINT_ARGS
    IWYU_ARGS
  )
  cmake_parse_arguments(IL
    "${options}"
    ""  # single value args
    "${multi_value_args}"
    ${ARGN}
  )

  if(NOT DEFINED CACHE{_CMAKE_CLANG_TIDY} OR
      NOT DEFINED CACHE{_CMAKE_CPPCHECK} OR
      NOT DEFINED CACHE{_CMAKE_CPPLINT} OR
      NOT DEFINED CACHE{_CMAKE_IWYU})
    setup_integrated_linters()
  endif()

  # TBD test langugage detection with INTERFACE or header-only targets
  get_target_property(c_standard "${target}" C_STANDARD)
  get_target_property(cxx_standard "${target}" CXX_STANDARD)
  get_target_property(sources "${target}" SOURCES)
  foreach(source ${sources})
    get_source_file_property(${source}_LANGUAGE ${source} LANGUAGE)
    if(${source}_LANGUAGE STREQUAL "C")
      set(c_source_files TRUE)
      if(cxx_source_files)
        break()
      endif()
    elseif(${source}_LANGUAGE STREQUAL "CXX")
      set(cxx_source_files TRUE)
      if(c_source_files)
        break()
      endif()
    endif()
  endforeach()

  # In order to avoid linters (or at least clang-tidy) parsing headers
  #   included from dependencies, we need to treat them as system headers.
  #   find_package() should already handle this for installed dependencies,
  #   presumably by checking CMAKE_SYSTEM_INCLUDE_PATH. But any dependencies
  #   sourced with FetchContent will need this extra step to be similarly
  #   omitted from generating linter errors.
  if(DEFINED FETCHCONTENT_BASE_DIR)
    get_all_target_dependencies(${target} deps)
    # build set of all dependency INTERFACE_INCLUDE_DIRECTORIES
    set(include_dirs)
    foreach(dep ${deps})
      get_target_property(interface_include_dirs ${dep}
        INTERFACE_INCLUDE_DIRECTORIES)
      if(interface_include_dirs)
        foreach(dir ${interface_include_dirs})
          if(NOT ${dir} IN_LIST include_dirs)
            list(APPEND include_dirs ${dir})
          endif()
        endforeach()
      endif()
    endforeach()
    # override transitive `-I` inclusions with `-isystem` inclusions for
    #   fetched dependencies
    foreach(dir ${include_dirs})
      if(dir MATCHES "${FETCHCONTENT_BASE_DIR}/")
        target_include_directories(${target} SYSTEM PUBLIC ${dir})
      endif()
    endforeach()
  endif()

  #
  # append target-specfic options to clang-tidy command line
  #
  if(_CMAKE_CLANG_TIDY AND
      NOT SKIP_ALL_CLANG_TIDY AND
      NOT IL_SKIP_CLANG_TIDY)
      # clang-tidy is only compatible with clang precompiled headers, see:
      #   - https://stackoverflow.com/a/76932426
      get_target_property(
        interface_precompile_headers "${target}" INTERFACE_PRECOMPILE_HEADERS)
      get_target_property(
        precompile_headers "${target}" PRECOMPILE_HEADERS)
      if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" OR  # Clang or AppleClang
          NOT (interface_precompile_headers OR precompile_headers))

        # Setting C|CXX_CPPCHECK causes this call at config time:
        #   cmake -E __run_co_compile --tidy="<C|CXX_CPPCHECK after first>" \
        #     --source=<target source> -- <compile command>
        #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmCommonTargetGenerator.cxx#L356
        # which has build call:
        #   <C|CXX_CLANG_TIDY (missing -p)> <target source> -- <compile command>
        # (CMake recommends passing `-p compile_commands.json` to clang-tidy
        #   to avoid problems when target compiler is not the system default.
        #   However in practice parsing the entire file just to filter out
        #   target source is not conducive to per-target linting, so we use the
        #   fallback method, passing the compile command after --.)
        #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L374

        # TBD find any relevant .clang-tidy, determine interactions with CLI

        set(c_clang_tidy_cmd "${_CMAKE_CLANG_TIDY}")
        set(cxx_clang_tidy_cmd "${_CMAKE_CLANG_TIDY}")

        string(JOIN "," c_cxx_tidy_checks
          "android-*"
          "bugprone-*"
          "cert-*-c"
          "concurrency-*"
          "fuschia-*"
          "misc-*"
        )
        string(JOIN "," cxx_only_tidy_checks
          "abseil-*"
          "boost-*"
          "cert-*-cpp"
          "cppcoreguidelines-*"
          "google-*"
          "hicpp-*"
          "modernize-*"
          "performance-*"
          "portability-*"
          "readability-*"
        )
        list(APPEND c_clang_tidy_cmd
          "--checks=${c_cxx_tidy_checks}")
        list(APPEND cxx_clang_tidy_cmd
          "--checks=${c_cxx_tidy_checks},${cxx_only_tidy_checks}")

        if(IL_CLANG_TIDY_ARGS)
          list(APPEND c_clang_tidy_cmd ${IL_CLANG_TIDY_ARGS})
          list(APPEND cxx_clang_tidy_cmd ${IL_CLANG_TIDY_ARGS})
        endif()

        if(c_source_files)
          set_target_properties("${target}" PROPERTIES
            C_CLANG_TIDY "${c_clang_tidy_cmd}")
        endif()
        if(cxx_source_files)
          set_target_properties("${target}" PROPERTIES
            CXX_CLANG_TIDY "${cxx_clang_tidy_cmd}")
        endif()

      endif()
  endif()

  #
  # append target-specfic options to cppcheck command line
  #
  if(_CMAKE_CPPCHECK AND
      NOT SKIP_ALL_CPPCHECK AND
      NOT IL_SKIP_CPPCHECK)
    # Setting C|CXX_CPPCHECK causes this call at config time:
    #   cmake -E __run_co_compile --cppcheck="<C|CXX_CPPCHECK after first>" \
    #     --source=<target source> -- <compile command>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmCommonTargetGenerator.cxx#L356
    # which has build call:
    #   <C|CXX_CPPCHECK> <compiler -D -U -I options> <target source>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L478

    set(c_cppcheck_cmd   "${_CMAKE_CPPCHECK}")
    set(cxx_cppcheck_cmd "${_CMAKE_CPPCHECK}")

    # TBD find .cppcheck in target source dir -> project root dir path like
    #   clang-tidy and cpplint, determine interaction with CLI args, pass with
    #   --project

    if(c_standard)
      if(c_standard EQUAL 90)
        list(APPEND c_cppcheck_cmd "--std=c89")
      else()
        list(APPEND c_cppcheck_cmd "--std=c${c_standard}")
      endif()
    endif()
    if(cxx_standard)
      list(APPEND cxx_cppcheck_cmd "--std=c++${cxx_standard}")
    endif()

    if(IL_CPPCHECK_ARGS)
      foreach(arg IL_CPPCHECK_ARGS)
        if("${arg}" MATCHES "^-(-std|[DIU])")
          message(FATAL_ERROR "No need to pass --std -D -I -U options to \
integrate_linting(CPPCHECK_ARGS), they will be auto-populated")
        endif()
      endforeach()
      list(APPEND c_cppcheck_cmd ${IL_CPPCHECK_ARGS})
      list(APPEND cxx_cppcheck_cmd ${IL_CPPCHECK_ARGS})
    endif()

    if(c_source_files)
      set_target_properties("${target}" PROPERTIES
        C_CPPCHECK "${c_cppcheck_cmd}")
    endif()
    if(cxx_source_files)
      set_target_properties("${target}" PROPERTIES
        CXX_CPPCHECK "${cxx_cppcheck_cmd}")
    endif()

  endif()

  #
  # append target-specfic options to cpplint command line
  #
  if(_CMAKE_CPPLINT AND
      NOT SKIP_ALL_CPPLINT AND
      NOT IL_SKIP_CPPLINT)
    # Setting C|CXX_CPPLINT causes this call at config time:
    #   cmake -E __run_co_compile --cpplint="<C|CXX_CPPLINT after first>" \
    #     --source=<target source> -- <compile command>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmCommonTargetGenerator.cxx#L356
    # which has build call:
    #   <C|CXX_CPPLINT> <target source>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L451

    # TBD find CPPLINT.cfg, determine interaction with CLI args

    set(cpplint_cmd "${_CMAKE_CPPLINT}")

    if(IL_CPPLINT_ARGS)
      list(APPEND cpplint_cmd ${IL_CPPLINT_ARGS})
    endif()

    if(c_source_files)
      set_target_properties("${target}" PROPERTIES
        C_CPPLINT "${cpplint_cmd}")
    endif()
    if(cxx_source_files)
      set_target_properties("${target}" PROPERTIES
        CXX_CPPLINT "${cpplint_cmd}")
    endif()

  endif()

  #
  # append target-specfic options to include-what-you-use command line
  #
  if(_CMAKE_IWYU AND
      NOT SKIP_ALL_IWYU AND
      NOT IL_SKIP_IWYU)
    # setting C|CXX_INCLUDE_WHAT_YOU_USE causes this call at config time:
    #   cmake -E __run_co_compile --iwyu="<C|CXX_INCLUDE_WHAT_YOU_USE after first>" \
    #     --source=<target source> -- <compile command>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmCommonTargetGenerator.cxx#L356
    # which has build call:
    #   <C|CXX_INCLUDE_WHAT_YOU_USE> <compile command>
    #   https://github.com/Kitware/CMake/blob/v3.27.4/Source/cmcmd.cxx#L342

    # TBD iwyu config files?

    set(c_iwyu_cmd "${_CMAKE_IWYU}")
    set(cxx_iwyu_cmd "${_CMAKE_IWYU}")

    if(_CXX_STANDARD GREATER_EQUAL 17)
      list(APPEND cxx_iwyu_cmd "-Xiwyu" "--cxx17ns")
    endif()

    if(IL_IWYU_ARGS)
      foreach(arg IL_IWYU_ARGS)
        if("${arg}" MATCHES "^--cxx17ns")
          message(FATAL_ERROR "No need to pass --cxx17ns option to \
integrate_linting(IWYU_ARGS), it will be auto-populated")
        endif()
      endforeach()
      list(APPEND c_iwyu_cmd ${IL_IWYU_ARGS})
      list(APPEND cxx_iwyu_cmd ${IL_IWYU_ARGS})
    endif()

    if(c_source_files)
      set_target_properties("${target}" PROPERTIES
        C_INCLUDE_WHAT_YOU_USE "${c_iwyu_cmd}")
    endif()
    if(cxx_source_files)
      set_target_properties("${target}" PROPERTIES
        CXX_INCLUDE_WHAT_YOU_USE "${cxx_iwyu_cmd}")
    endif()

  endif()

  # more efficient than querying set of C(XX)_<linter> properties
  set_target_properties(${target} PROPERTIES
    INTEGRATED_LINTING TRUE)

endfunction()
