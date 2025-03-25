# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_rtf_FOUND OR sdl2_rtf_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_rtf_FOUND
    SDL2_rtf_VERSION
    SDL2_rtf_VERSION_MAJOR
    SDL2_rtf_VERSION_MINOR
    SDL2_rtf_VERSION_PATCH
    SDL2_rtf_VERSION_TWEAK
    SDL2_rtf_VERSION_COUNT
    # sdl2_rtf-config.cmake, see: https://github.com/libsdl-org/SDL_rtf/blob/SDL2/sdl2_rtf-config.cmake.in
    #SDL2_rtf_FOUND
    # FetchContent standard
    sdl2_rtf_POPULATED
    sdl2_rtf_SOURCE_DIR
    sdl2_rtf_BINARY_DIR
  )

  # current release at last script update (requires SDL 2.0.16+ due to use of
  #   SDL_islower (2.0.12) and SDL_isalpha (2.0.16)) (hash is from commit with
  #   first appearance of sdl2_rtf-config-version.cmake.in)
  set(minimum_version "2.0.0")  # ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b
  # latest release at last script update:
  set(current_version "2.0.0")  # 09fa7ee967b9b2ca02ed60c8193f1a7c34221657
  # repo has no tags set, so we must identify current_version by commit hash:
  set(current_version_commit_hash "09fa7ee967b9b2ca02ed60c8193f1a7c34221657")

  #[[
  include(SetDefaultSDL2_rtfVersion)
  if(NOT SDL2_RTF_DEFAULT_VERSION OR
      "${SDL2_RTF_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_RTF_DEFAULT_VERSION}")
  endif()
  ]]

  set(fp_options
    # sdl2_rtf-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL_rtf/blob/ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b/sdl2_rtf-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  set(fc_options
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL_rtf.git"
    GIT_TAG        "${current_version_commit_hash}"
    GIT_SHALLOW
  )

  # SDL_rtf 2.0.0 does not use SDL2RTF_VENDORED
  # set(SDL2RTF_VENDORED ON)
  # Disabling install to avoid dependency export set errors, see:
  #   - https://github.com/libsdl-org/SDL_rtf/blob/ef8e0b90ab1ff43ac87bda69e5ec297bb5014e8b/CMakeLists.txt#L52
  set(SDL2RTF_INSTALL OFF)
  fetch_if_not_found(SDL2_rtf "${fp_options}" "${fc_options}")

endblock()
