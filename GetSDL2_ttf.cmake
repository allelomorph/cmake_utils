# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_ttf_FOUND OR sdl2_ttf_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# first release with optional install (requires SDL2 2.0.10):
set(SDL_TTF_MINIMUM_VERSION "2.20.0")  # b31ee728430e71f1f6e927f89284af9fd58bd1d9
# latest release at last script update:
set(SDL_TTF_CURRENT_VERSION "2.22.0")  # 4a318f8dfaa1bb6f10e0c5e54052e25d3c7f3440

if(NOT SDL_TTF_DEFAULT_VERSION OR
    "${SDL_TTF_DEFAULT_VERSION}" VERSION_LESS "${SDL_TTF_MINIMUM_VERSION}")
  set(SDL_TTF_TARGET_VERSION "${SDL_TTF_MINIMUM_VERSION}")
else()
  set(SDL_TTF_TARGET_VERSION "${SDL_TTF_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # sdl2_ttf-config-version.cmake sets any version higher than requested as
  #   compatible, see:
  #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
  #   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/sdl2_ttf-config-version.cmake.in
  "${SDL_TTF_MINIMUM_VERSION}"
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY "https://github.com/libsdl-org/SDL_ttf.git"
  GIT_TAG        "release-${SDL_TTF_TARGET_VERSION}"
)
# override SDL_ttf 2.20.0+ option SDL2TTF_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/CMakeLists.txt#L52
set(SDL2TTF_VENDORED ON)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/CMakeLists.txt#L51
set(SDL2TTF_INSTALL OFF)
fetch_if_not_found(SDL2_ttf "${FP_OPTIONS}" "${FC_OPTIONS}")
