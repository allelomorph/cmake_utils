# newest features used: TBD
cmake_minimum_required(VERSION 3.14)

# prevent redundancy by testing for use in parent projects
if(SDL2_image_FOUND OR sdl2_image_POPULATED)
  return()
endif()

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

block(SCOPE_FOR VARIABLES PROPAGATE
    # find_package standard
    SDL2_image_FOUND
    SDL2_image_VERSION
    SDL2_image_VERSION_MAJOR
    SDL2_image_VERSION_MINOR
    SDL2_image_VERSION_PATCH
    SDL2_image_VERSION_TWEAK
    SDL2_image_VERSION_COUNT
    # sdl2_image-config.cmake, see: https://github.com/libsdl-org/SDL_image/blob/release-2.8.2/sdl2_image-config.cmake.in
    #SDL2_image_FOUND
    # FetchContent standard
    sdl2_image_POPULATED
    sdl2_image_SOURCE_DIR
    sdl2_image_BINARY_DIR
  )

  # first release supporting cmake (requires SDL 2.0.9):
  set(minimum_version "2.6.0")  # 7b3347c0d90d1f1e9cc4e06e145432697ca4e68f
  # latest release at last script update
  set(current_version "2.8.2")  # abcf63aa71b4e3ac32120fa9870a6500ddcdcc89

  include(SetDefaultSDL2_imageVersion)
  if(NOT SDL2_IMAGE_DEFAULT_VERSION OR
      "${SDL2_IMAGE_DEFAULT_VERSION}" VERSION_LESS "${minimum_version}")
    set(target_version "${minimum_version}")
  else()
    set(target_version "${SDL2_IMAGE_DEFAULT_VERSION}")
  endif()

  set(fp_options
    # sdl2_image-config-version.cmake sets any version higher than requested as
    #   compatible, see:
    #   - https://cmake.org/cmake/help/v3.14/command/find_package.html#version-selection
    #   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/sdl2_image-config-version.cmake.in
    "${minimum_version}"
    # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
    #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
    #   - https://wiki.libsdl.org/SDL2/README/cmake
    CONFIG
  )

  # SDL_image release-v2.8.8 (latest SDL2 tag at time of writing) uses git
  #   submodules for its dependencies in external/, see:
  #   - https://github.com/libsdl-org/SDL_image/tree/release-2.8.8/external
  #   Cloning is much quicker when using --shallow-submodules so that all repos
  #   are at a depth of 1. However, while FetchContent supports --depth 1
  #   (GIT_SHALLOW) and --recurse-submodules (GIT_SUBMODULES_RECURSE,) it does not
  #   support --shallow-submodules:
  #   - https://gitlab.kitware.com/cmake/cmake/-/issues/16144
  #   So, we must use a custom DOWNLOAD_COMMAND.
  set(bash_prefix     "/usr/bin/bash" "-c")
  set(git_repository  "https://github.com/libsdl-org/SDL_image.git")
  set(git_tag         "release-${target_version}")
  set(fc_src_dir      "${FETCHCONTENT_BASE_DIR}/sdl2_image-src")
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

  # override SDL_image 2.6.0+ option SDL2IMAGE_VENDORED to force building of
  #   dependencies from source, see:
  #   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/CMakeLists.txt#L51
  set(SDL2IMAGE_VENDORED ON)
  # Disabling install to avoid dependency export set errors, see:
  #   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.0/CMakeLists.txt#L51
  set(SDL2IMAGE_INSTALL OFF)

  fetch_if_not_found(SDL2_image "${fp_options}" "${fc_options}")

endblock()
