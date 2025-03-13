# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_mixer_FOUND OR sdl2_mixer_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

include(SetDefaultSDL2_mixerVersion)

# first release supporting cmake (requires SDL 2.0.9):
set(SDL_MIXER_MINIMUM_VERSION "2.6.0")  # 738611693dc324001cc00f5b800e3d18fb42cb4e
# latest release at last script update
set(SDL_MIXER_CURRENT_VERSION "2.8.0")  # a37e09f85d321a13dfcf0d4432827ee09beeb623

if(NOT SDL2_MIXER_DEFAULT_VERSION OR
    "${SDL2_MIXER_DEFAULT_VERSION}" VERSION_LESS "${SDL_MIXER_MINIMUM_VERSION}")
  set(SDL_MIXER_TARGET_VERSION "${SDL_MIXER_MINIMUM_VERSION}")
else()
  set(SDL_MIXER_TARGET_VERSION "${SDL2_MIXER_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # sdl2_mixer-config-version.cmake sets any version higher than requested as
  #   compatible, see:
  #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
  #   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/sdl2_mixer-config-version.cmake.in
  "${SDL_MIXER_MINIMUM_VERSION}"
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
set(_bash_prefix     "/usr/bin/bash" "-c")
set(_git_repository  "https://github.com/libsdl-org/SDL_mixer.git")
set(_git_tag         "release-${SDL_MIXER_TARGET_VERSION}")
set(_fc_src_dir      "${FETCHCONTENT_BASE_DIR}/sdl2_mixer-src")
set(_clone_options
  "--branch ${_git_tag} --depth 1 --recurse-submodules --shallow-submodules")
set(FC_OPTIONS
  # Each *_COMMAND works best when internally idempotent, always exits with 0,
  #   and contains no enescaped semicolons
  DOWNLOAD_COMMAND ${_bash_prefix}
    "[[ -d ${_fc_src_dir}/.git ]] || \
      git clone ${_clone_options} ${_git_repository} ${_fc_src_dir}"
)
# override SDL_mixer 2.6.0+ option SDL2MIXER_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L60
set(SDL2MIXER_VENDORED ON)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L58
set(SDL2MIXER_INSTALL OFF)
fetch_if_not_found(SDL2_mixer "${FP_OPTIONS}" "${FC_OPTIONS}")

unset(FP_OPTIONS)
unset(_bash_prefix)
unset(_git_repository)
unset(_git_tag)
unset(_fc_src_dir)
unset(_clone_options)
unset(FC_OPTIONS)
