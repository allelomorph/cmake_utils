# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# See https://packages.ubuntu.com/search?keywords=sdl2 for package versions
# In all cases currently only considering SDL2 v2, not v3
#
# Relevant SDL2_ttf releases:
# - release matching Ubuntu 20.04 LTS package:
#   2.0.15 33cdd1881e31184b49a68b4890d1d256fc0c6dc1
# - release matching Ubuntu 22.04 LTS package:
#   2.0.18 3e702ed9bf400b0a72534f144b8bec46ee0416cb
# - release matching Ubuntu 23.10 package: (requires SDL2 2.0.10)
#   2.20.2 89d1692fd8fe91a679bb943d377bfbd709b52c23
set(FP_OPTIONS
  2.0.15
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY https://github.com/libsdl-org/SDL_ttf.git
  GIT_TAG        release-2.20.2
)
# override SDL_ttf 2.20.0+ option SDL2TTF_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.2/CMakeLists.txt#L52
set(SDL2TTF_VENDORED TRUE)
# Disabling install avoids errors like:
#   `CMake Error: install(EXPORT "SDL2_ttfTargets" ...) includes target "SDL2_ttf" which requires target "SDL2" that is not in any export set.`
#   - https://github.com/libsdl-org/SDL_ttf/blob/release-2.20.2/CMakeLists.txt#L51
set(SDL2TTF_INSTALL OFF)
fetch_if_not_found(SDL2_ttf "${FP_OPTIONS}" "${FC_OPTIONS}")
