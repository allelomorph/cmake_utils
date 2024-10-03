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
set(FC_OPTIONS
  GIT_REPOSITORY "https://github.com/libsdl-org/SDL_mixer.git"
  GIT_TAG        "release-${SDL_MIXER_TARGET_VERSION}"
)
# override SDL_mixer 2.6.0+ option SDL2MIXER_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L60
set(SDL2MIXER_VENDORED ON)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.0/CMakeLists.txt#L58
set(SDL2MIXER_INSTALL OFF)
fetch_if_not_found(SDL2_mixer "${FP_OPTIONS}" "${FC_OPTIONS}")
