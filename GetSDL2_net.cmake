# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# See https://packages.ubuntu.com/search?keywords=sdl2 for package versions
# In all cases currently only considering SDL2 v2, not v3
#
# Relevant SDL2_net releases:
# - release matching Ubuntu 20.04 LTS and 22.04 LTS packages: (no
#     CMakeLists.txt, required SDL2 version unknown)
#   2.0.1 6e513e390d18ad7950d9082863bfe33a0c62fd71
# - earliest stable release to use CMakeLists.txt, and release matching Ubuntu
#     23.10 package: (requires SDL2 2.0.9)
#   2.2.0 669e75b84632e2c6cc5c65974ec9e28052cb7a4e
set(FP_OPTIONS
  2.0.1
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY https://github.com/libsdl-org/SDL_net.git
  GIT_TAG        release-2.2.0
)
# SDL_net 2.2.0 does not use a SDL2*_VENDORED option like other SDL2 extension
#   libs, and much like SDL2 itself, automatically skips installation if it is
#   not the top-level project, see:
#   - https://github.com/libsdl-org/SDL_net/blob/release-2.2.0/CMakeLists.txt
#set(SDL2NET_VENDORED TRUE)
#set(SDL2NET_INSTALL OFF)
fetch_if_not_found(SDL2_net "${FP_OPTIONS}" "${FC_OPTIONS}")
