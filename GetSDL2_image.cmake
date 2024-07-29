# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# See https://packages.ubuntu.com/search?keywords=sdl2 for package versions
# In all cases currently only considering SDL2 v2, not v3
#
# Relevant SDL2_image releases:
# - release matching Ubuntu 20.04 LTS and Ubuntu 22.04 LTS packages:
#   2.0.5 (not listed on github, commit hash unknown)
# - earliest listed release:
#   2.0.8 e9fc66a038304be0b892b83c16d6dcf5ee36f388
# - release matching Ubuntu 23.10 package (requires SDL 2.0.9)
#   2.6.3 d3c6d5963dbe438bcae0e2b6f3d7cfea23d02829
set(FP_OPTIONS
  2.0.5
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
  )
set(FC_OPTIONS
  GIT_REPOSITORY https://github.com/libsdl-org/SDL_image.git
  GIT_TAG        release-2.6.3
)
# override SDL_image 2.6.0+ option SDL2IMAGE_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.3/CMakeLists.txt#L51
set(SDL2IMAGE_VENDORED TRUE)
# Disabling install avoids errors like:
#   `CMake Error: install(EXPORT "SDL2ImageExports" ...) includes target "SDL2_image" which requires target "SDL2" that is not in any export set.`
#   - https://github.com/libsdl-org/SDL_image/blob/release-2.6.3/CMakeLists.txt#L49
set(SDL2IMAGE_INSTALL OFF)
fetch_if_not_found(SDL2_image "${FP_OPTIONS}" "${FC_OPTIONS}")
