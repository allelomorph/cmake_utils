# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_FOUND OR sdl2_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_FOUND
    SDL2_VERSION
    SDL2_VERSION_MAJOR
    SDL2_VERSION_MINOR
    SDL2_VERSION_PATCH
    SDL2_VERSION_TWEAK
    SDL2_VERSION_COUNT
    # sdl2-config.cmake, see: https://github.com/libsdl-org/SDL/blob/release-2.30.0/sdl2-config.cmake.in
    SDL2_INCLUDE_DIRS
    SDL2_LIBRARIES
    SDL2_STATIC_LIBRARIES
    #SDL2TEST_LIBRARY
    #SDL2MAIN_LIBRARY
    #SDL2_SDL2main_FOUND
    #SDL2_SDL2_FOUND
    #SDL2_SDL2-static_FOUND
    #SDL2_SDL2test_FOUND
    # FetchContent standard
    sdl2_POPULATED
    sdl2_SOURCE_DIR
    sdl2_BINARY_DIR
  )

  # earliest release to satisfy all of the following:
  #   - defines targets SDL2::SDL2 and SDL2::SDL2main
  #   - supports recent releases of SDL_image, see:
  #     - https://github.com/libsdl-org/SDL_image/blob/release-2.8.2/CMakeLists.txt#L9
  #   - supports recent releases of SDL_mixer, see:
  #     - https://github.com/libsdl-org/SDL_mixer/blob/release-2.8.0/CMakeLists.txt#L9
  #   - supports recent releases of SDL_mixer, see:
  #     - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/CMakeLists.txt#L9
  #   - supports recent releases of SDL_rtf: while SDL_rtf 2.0.0 claims to require
  #     SDL 2.0.0, it also uses SDL_islower and SDL_isalpha, which are not defined
  #     until SDL 2.0.12 and 2.0.16, see:
  #     - https://github.com/libsdl-org/SDL_rtf/blob/09fa7ee967b9b2ca02ed60c8193f1a7c34221657/CMakeLists.txt#L9
  #     - https://github.com/libsdl-org/SDL/commit/aa384ad02b6e93ceb38c88ea2f3a8079bf0a0b64
  #     - https://github.com/libsdl-org/SDL/commit/dfe219ec715e465328dc72bd03712ef435b0eb3c
  #   - supports recent releases of SDL_ttf, see:
  #     - https://github.com/libsdl-org/SDL_ttf/blob/release-2.22.0/CMakeLists.txt#L9
  set(minimum_version "2.0.16")  # 25f9ed87ff6947d9576fc9d79dee0784e638ac58
  # latest release at last script update
  set(current_version "2.30.7")  # 9519b9916cd29a14587af0507292f2bd31dd5752

  include(SetDefaultSDL2Version)
  if(NOT SDL2_DEFAULT_VERSION OR
      "${SDL2_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_DEFAULT_VERSION}")
  endif()

  set(fp_options
    # sdl2-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL/blob/release-2.0.16/sdl2-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  set(fc_options
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL.git"
    GIT_TAG        "release-${target_version}"
  )

  # CMAKE_CACHE_ARGS not passed by FetchContent to ExternalProject_Add as documented in:
  #   https://cmake.org/cmake/help/v3.16/module/FetchContent.html#command:fetchcontent_declare
  #   https://cmake.org/cmake/help/v3.16/module/ExternalProject.html#command:externalproject_add
  # So we set the cache variable directly instead of passing with `-D`, see:
  #   https://discourse.cmake.org/t/fetchcontent-cache-variables/1538
  set(SDL_STATIC OFF CACHE BOOL "Toggles building of SDL2 static library")
  # After 2.24.0 SDL2 CMakeLists.txt automatically disables install if not
  #   configuring as top-level project, see:
  #   - https://github.com/libsdl-org/SDL/commit/d63a699e015ca09f2fbab1d917de98f62f950e5d
  if("${target_version}" VERSION_LESS "2.24.0")
    set(SDL2_DISABLE_INSTALL ON)
  endif()

  fetch_if_not_found(SDL2 "${fp_options}" "${fc_options}")

endblock()
