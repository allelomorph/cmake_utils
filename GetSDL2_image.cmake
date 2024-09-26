# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# first release supporting cmake (requires SDL 2.0.9):
set(SDL_IMAGE_MINIMUM_VERSION "2.6.0")  # 7b3347c0d90d1f1e9cc4e06e145432697ca4e68f
# latest release at last script update
set(SDL_IMAGE_CURRENT_VERSION "2.8.2")  # abcf63aa71b4e3ac32120fa9870a6500ddcdcc89

if(NOT SDL_IMAGE_DEFAULT_VERSION OR
    "${SDL_IMAGE_DEFAULT_VERSION}" VERSION_LESS "${SDL_IMAGE_MINIMUM_VERSION}")
  set(SDL_IMAGE_TARGET_VERSION "${SDL_IMAGE_MINIMUM_VERSION}")
else()
  set(SDL_IMAGE_TARGET_VERSION "${SDL_IMAGE_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # sdl2_image-config-version.cmake sets any version higher than requested as
  #   compatible, see:
  #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
  #   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/sdl2_image-config-version.cmake.in
  "${SDL_IMAGE_MINIMUM_VERSION}"
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
  )
set(FC_OPTIONS
  GIT_REPOSITORY "https://github.com/libsdl-org/SDL_image.git"
  GIT_TAG        "release-${SDL_IMAGE_TARGET_VERSION}"
)
# override SDL_image 2.6.0+ option SDL2IMAGE_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/CMakeLists.txt#L51
set(SDL2IMAGE_VENDORED ON)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/CMakeLists.txt#L51
set(SDL2IMAGE_INSTALL OFF)
fetch_if_not_found(SDL2_image "${FP_OPTIONS}" "${FC_OPTIONS}")
