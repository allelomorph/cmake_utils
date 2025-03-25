# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_net_FOUND OR sdl2_net_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_net_FOUND
    SDL2_net_VERSION
    SDL2_net_VERSION_MAJOR
    SDL2_net_VERSION_MINOR
    SDL2_net_VERSION_PATCH
    SDL2_net_VERSION_TWEAK
    SDL2_net_VERSION_COUNT
    # sdl2_net-config.cmake, see: https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/sdl2_net-config.cmake.in
    #SDL2_net_FOUND
    # FetchContent standard
    sdl2_net_POPULATED
    sdl2_net_SOURCE_DIR
    sdl2_net_BINARY_DIR
  )

  # first release supporting cmake (requires SDL 2.0.9):
  set(minimum_version "2.2.0")  # 669e75b84632e2c6cc5c65974ec9e28052cb7a4e
  # latest release at last script update
  set(current_version "2.2.0")  # 669e75b84632e2c6cc5c65974ec9e28052cb7a4e

  include(SetDefaultSDL2_netVersion)
  if(NOT SDL2_NET_DEFAULT_VERSION OR
      "${SDL2_NET_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_NET_DEFAULT_VERSION}")
  endif()

  set(fp_options
    # sdl2_net-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/sdl2_net-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  set(fc_options
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL_net.git"
    GIT_TAG        "release-${target_version}"
    GIT_SHALLOW
  )

  # SDL_net 2.2.0 does not use SDL2NET_VENDORED
  # set(SDL2NET_VENDORED ON)
  # Although much like SDL core, SDL_net 2.2.0 detects whether project is top-level
  #   and sets SDL2NET_INSTALL to OFF if not, setting it anyway as a precaution, see:
  #   - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/CMakeLists.txt#L51
  set(SDL2NET_INSTALL OFF)
  fetch_if_not_found(SDL2_net "${fp_options}" "${fc_options}")

endblock()
