# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# See https://packages.ubuntu.com/search?keywords=sdl2 for package versions
# In all cases currently only considering SDL2 v2, not v3
#
# Relevant SDL2_rtf releases:
# - !!! Does not appear as Ubuntu 20.04 LTS, 22.04 LTS, or 23.10 package
# - current v2 release at last script update: (requires SDL2 2.0.16
#     due to use of SDL_islower (2.0.12+) and SDL_isalpha (2.0.16+))
#   2.0.0 f93334ac8cf40ca5b2dc63adf9ce1c3704b832d1
set(FP_OPTIONS
  2.0.0
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY https://github.com/libsdl-org/SDL_rtf.git
  GIT_TAG        f93334ac8cf40ca5b2dc63adf9ce1c3704b832d1 # 2.0.0 (repo has no tags)
)
# SDL_rtf 2.0.0 does not use SDL2RTF_VENDORED
# set(SDL2TTF_VENDORED TRUE)
# Disabling install to avoid dependency export set errors, see:
#   - https://github.com/libsdl-org/SDL_rtf/blob/f93334ac8cf40ca5b2dc63adf9ce1c3704b832d1/CMakeLists.txt#L55
set(SDL2RTF_INSTALL OFF)
fetch_if_not_found(SDL2_rtf "" "${FC_OPTIONS}")
