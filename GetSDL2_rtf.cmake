# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_rtf_FOUND OR sdl2_rtf_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

include(SetDefaultSDL2_rtfVersion)

# current release at last script update (requires SDL 2.0.16+ due to use of
#   SDL_islower (2.0.12) and SDL_isalpha (2.0.16)) (hash is from commit with
#   first appearance of sdl2_rtf-config-version.cmake.in)
set(SDL_RTF_MINIMUM_VERSION "2.0.0")  # ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b
# latest release at last script update (repo has no tags set):
set(SDL_RTF_CURRENT_VERSION "2.0.0")  # 09fa7ee967b9b2ca02ed60c8193f1a7c34221657
set(SDL_RTF_CURRENT_VERSION_COMMIT_HASH "09fa7ee967b9b2ca02ed60c8193f1a7c34221657")

if(NOT SDL2_RTF_DEFAULT_VERSION OR
    "${SDL2_RTF_DEFAULT_VERSION}" VERSION_LESS "${SDL_RTF_MINIMUM_VERSION}")
  set(SDL_RTF_TARGET_VERSION "${SDL_RTF_MINIMUM_VERSION}")
else()
  set(SDL_RTF_TARGET_VERSION "${SDL2_RTF_DEFAULT_VERSION}")
endif()

set(FP_OPTIONS
  # sdl2_rtf-config-version.cmake sets any version higher than requested as
  #   compatible, see:
  #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
  #   - https://github.com/libsdl-org/SDL_rtf/blob/ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b/sdl2_rtf-config-version.cmake.in
  "${SDL_RTF_MINIMUM_VERSION}"
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY "https://github.com/libsdl-org/SDL_rtf.git"
  GIT_TAG        "${SDL_RTF_CURRENT_VERSION_COMMIT_HASH}"
)
# SDL_rtf 2.0.0 does not use SDL2RTF_VENDORED
# set(SDL2RTF_VENDORED ON)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_rtf/blob/ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b/CMakeLists.txt#L52
set(SDL2RTF_INSTALL OFF)
fetch_if_not_found(SDL2_rtf "${FP_OPTIONS}" "${FC_OPTIONS}")
