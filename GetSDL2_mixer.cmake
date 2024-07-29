# newest features used: FetchContent v3.11, FetchContent_MakeAvailable v3.14
cmake_minimum_required(VERSION 3.14)

if(NOT COMMAND fetch_if_not_found)
  include(FetchIfNotFound)
endif()

# See https://packages.ubuntu.com/search?keywords=sdl2 for package versions
# In all cases currently only considering SDL2 v2, not v3
#
# Relevant SDL2_mixer releases:
# - release matching Ubuntu 20.04 LTS and 22.04 LTS packages: (no
#     CMakeLists.txt, required SDL2 version unknown)
#   2.0.4 da75a58c19de9fedea62724a5f7770cbbe39adf9
# - earliest stable release to use CMakeLists.txt: (requires SDL2 2.0.9)
#   2.6.0 738611693dc324001cc00f5b800e3d18fb42cb4e
# - release matching Ubuntu 23.10 package: (requires SDL2 2.0.9)
#   2.6.3 6103316427a8479e5027e41ab9948bebfc1c3c19
set(FP_OPTIONS
  2.6.0
  # cmake-supplied FindSDL*.cmake modules (through v3.30 at least) are written
  #   for SDL1.x, and SDL2 has switched to preferring config mode, see:
  #   - https://wiki.libsdl.org/SDL2/README/cmake
  CONFIG
)
set(FC_OPTIONS
  GIT_REPOSITORY https://github.com/libsdl-org/SDL_mixer.git
  GIT_TAG        release-2.6.3
)
# override SDL_mixer 2.6.0+ option SDL2MIXER_VENDORED to force building of
#   dependencies from source, see:
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.3/CMakeLists.txt#L60
set(SDL2MIXER_VENDORED TRUE)
# Disabling install avoids errors like:
#   `CMake Error: install(EXPORT "SDL2MixerTargets" ...) includes target "SDL2_mixer" which requires target "SDL2" that is not in any export set.`
#   - https://github.com/libsdl-org/SDL_mixer/blob/release-2.6.3/CMakeLists.txt#L58
set(SDL2MIXER_INSTALL OFF)
fetch_if_not_found(SDL2_mixer "${FP_OPTIONS}" "${FC_OPTIONS}")
