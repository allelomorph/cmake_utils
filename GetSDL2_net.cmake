# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_net_FOUND OR sdl2_net_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# first release supporting cmake (requires SDL 2.0.9):
set(SDL_NET_MINIMUM_VERSION "2.2.0")  # 669e75b84632e2c6cc5c65974ec9e28052cb7a4e
# latest release at last script update
set(SDL_NET_CURRENT_VERSION "2.2.0")  # 669e75b84632e2c6cc5c65974ec9e28052cb7a4e

if(NOT SDL_NET_DEFAULT_VERSION OR
    "${SDL_NET_DEFAULT_VERSION}" VERSION_LESS "${SDL_NET_MINIMUM_VERSION}")
  set(SDL_NET_TARGET_VERSION "${SDL_NET_MINIMUM_VERSION}")
else()
  set(SDL_NET_TARGET_VERSION "${SDL_NET_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # sdl2_net-config-version.cmake sets any version higher than requested as
  #   compatible, see:
  #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
  #   - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/sdl2_net-config-version.cmake.in
  "${SDL_NET_MINIMUM_VERSION}"
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY "https://github.com/libsdl-org/SDL_net.git"
  GIT_TAG        "release-${SDL_NET_TARGET_VERSION}"
)
# SDL_net 2.2.0 does not use SDL2NET_VENDORED
# set(SDL2NET_VENDORED ON)
# Although much like SDL core, SDL_net 2.2.0 detects whether project is top-level
#   and sets SDL2NET_INSTALL to OFF if not, setting it anyway as a precaution, see:
#   - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/CMakeLists.txt#L51
set(SDL2NET_INSTALL OFF)
fetch_if_not_found(SDL2_net "${FP_OPTIONS}" "${FC_OPTIONS}")
