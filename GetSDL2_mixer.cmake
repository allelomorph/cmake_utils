# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_mixer_FOUND OR sdl2_mixer_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

if(NOT COMMAND record_variable_state OR
    NOT COMMAND restore_variable_state)
  include(RecordVariableState)
endif()

# In theory, dependencies configured with FetchContent should maintain their own
#   subbuild cache. In practice, sometimes calls to option() or set(CACHE) will
#   set variables in the parent project's cache, which can cause problems. Here
#   it is SDL_mixer's submodule dependency WavPack and its call to
#   cmake_dependent_option(BUILD_TESTING), which can cache BUILD_TESTING=OFF in
#   the parent cache, affecting later calls to include(CTest) in sibling
#   subprojects or on subsequent configs. To prevent this, we record the current
#   project's state of the BUILD_TESTING variable, and restore it at the end of
#   the fetching process. An alternative solution would be to simply set
#   SDL2MIXER_WAVPACK to OFF before the SDL_mixer config.
#   - https://github.com/libsdl-org/SDL_mixer/tree/release-2.8.1/external
#   - https://github.com/libsdl-org/WavPack/blob/02efabe73e1ac743ec35885f2b620cec3e996ca5/CMakeLists.txt#L145
#   - https://cmake.org/cmake/help/latest/module/CMakeDependentOption.html
record_variable_state(BUILD_TESTING)

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_mixer_FOUND
    SDL2_mixer_VERSION
    SDL2_mixer_VERSION_MAJOR
    SDL2_mixer_VERSION_MINOR
    SDL2_mixer_VERSION_PATCH
    SDL2_mixer_VERSION_TWEAK
    SDL2_mixer_VERSION_COUNT
    # sdl2_mixer-config.cmake, see: https://github.com/libsdl-org/SDL_mixer/blob/release-2.8.0/sdl2_mixer-config.cmake.in
    #SDL2_mixer_FOUND
    # FetchContent standard
    sdl2_mixer_POPULATED
    sdl2_mixer_SOURCE_DIR
    sdl2_mixer_BINARY_DIR
  )

  # first release supporting cmake (requires SDL 2.0.9):
  set(minimum_version "2.6.0")  # 738611693dc324001cc00f5b800e3d18fb42cb4e
  # latest release at last script update
  set(current_version "2.8.0")  # a37e09f85d321a13dfcf0d4432827ee09beeb623

  include(SetDefaultSDL2_mixerVersion)
  if(NOT SDL2_MIXER_DEFAULT_VERSION OR
      "${SDL2_MIXER_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_MIXER_DEFAULT_VERSION}")
  endif()

  set(fp_options
    # sdl2_mixer-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/sdl2_mixer-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  # SDL_mixer release-v2.8.1 (latest tag at time of writing) uses git submodules
  #   for its dependencies in external/, see:
  #   - https://github.com/libsdl-org/SDL_mixer/tree/release-2.8.1/external
  #   Cloning is much quicker when using --shallow-submodules so that all repos
  #   are at a depth of 1. However, while FetchContent supports --depth 1
  #   (GIT_SHALLOW) and --recurse-submodules (GIT_SUBMODULES_RECURSE,) it does not
  #   support --shallow-submodules:
  #   - https://gitlab.kitware.com/cmake/cmake/-/issues/16144
  #   So, we must use a custom DOWNLOAD_COMMAND.
  set(bash_prefix     "/usr/bin/bash" "-c")
  set(git_repository  "https://github.com/libsdl-org/SDL_mixer.git")
  set(git_tag         "release-${target_version}")
  set(fc_src_dir      "${FETCHCONTENT_BASE_DIR}/sdl2_mixer-src")
  set(clone_options
    "--branch ${git_tag} --depth 1 --recurse-submodules --shallow-submodules")
  set(fc_options
  # Each *_COMMAND works best when internally idempotent, always exits with 0,
  #   and contains no enescaped semicolons
  DOWNLOAD_COMMAND
    ${bash_prefix}
    "[[ -d ${fc_src_dir}/.git ]] || \
      git clone ${clone_options} ${git_repository} ${fc_src_dir}"
  )

  # override SDL_mixer 2.6.0+ option SDL2MIXER_VENDORED to force building of
  #   dependencies from source, see:
  #   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L60
  set(SDL2MIXER_VENDORED ON)
  # Disabling install to avoid dependency export set errors, see:
  #   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L58
  set(SDL2MIXER_INSTALL OFF)
  fetch_if_not_found(SDL2_mixer "${fp_options}" "${fc_options}")

endblock()

# Using default docstring from CTest.cmake option(BUILD_TESTING) call, see:
#   - https://github.com/Kitware/CMake/blob/v3.31.0/Modules/CTest.cmake#L50
restore_variable_state(BUILD_TESTING
  TYPE BOOL
  DOCSTRING "Build the testing tree.")
