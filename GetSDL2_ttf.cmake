# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_ttf_FOUND OR sdl2_ttf_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_ttf_FOUND
    SDL2_ttf_VERSION
    SDL2_ttf_VERSION_MAJOR
    SDL2_ttf_VERSION_MINOR
    SDL2_ttf_VERSION_PATCH
    SDL2_ttf_VERSION_TWEAK
    SDL2_ttf_VERSION_COUNT
    # sdl2_ttf-config.cmake, see: https://github.com/libsdl-org/SDL_ttf/blob/release-2.22.0/sdl2_ttf-config.cmake.in
    #SDL2_ttf_FOUND
    # FetchContent standard
    sdl2_ttf_POPULATED
    sdl2_ttf_SOURCE_DIR
    sdl2_ttf_BINARY_DIR
  )

  # first release with optional install (requires SDL2 2.0.10):
  set(minimum_version "2.20.0")  # b31ee728430e71f1f6e927f89284af9fd58bd1d9
  # latest release at last script update:
  set(current_version "2.22.0")  # 4a318f8dfaa1bb6f10e0c5e54052e25d3c7f3440

  include(SetDefaultSDL2_ttfVersion)
  if(NOT SDL2_TTF_DEFAULT_VERSION OR
      "${SDL2_TTF_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_TTF_DEFAULT_VERSION}")
  endif()

  set(fp_options
    # sdl2_ttf-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/sdl2_ttf-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  # SDL_ttf release-v2.24.0 (latest SDL2 tag at time of writing) uses git
  #   submodules for its dependencies in external/, see:
  #   - https://github.com/libsdl-org/SDL_ttf/tree/release-2.24.0/external
  #   Cloning is much quicker when using --shallow-submodules so that all repos
  #   are at a depth of 1. However, while FetchContent supports --depth 1
  #   (GIT_SHALLOW) and --recurse-submodules (GIT_SUBMODULES_RECURSE,) it does not
  #   support --shallow-submodules:
  #   - https://gitlab.kitware.com/cmake/cmake/-/issues/16144
  #   So, we must use a custom DOWNLOAD_COMMAND.
  set(bash_prefix     "/usr/bin/bash" "-c")
  set(git_repository  "https://github.com/libsdl-org/SDL_ttf.git")
  set(git_tag         "release-${target_version}")
  set(fc_src_dir      "${FETCHCONTENT_BASE_DIR}/sdl2_ttf-src")
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

  # override SDL_ttf 2.20.0+ option SDL2TTF_VENDORED to force building of
  #   dependencies from source, see:
  #   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/CMakeLists.txt#L52
  set(SDL2TTF_VENDORED ON)
  # Disabling install to avoid dependency export set errors, see:
  #   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.0/CMakeLists.txt#L51
  set(SDL2TTF_INSTALL OFF)
  fetch_if_not_found(SDL2_ttf "${fp_options}" "${fc_options}")

endblock()
