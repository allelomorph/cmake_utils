cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

if(NOT COMMAND determine_package_manager)
  include(DeterminePackageManager)
endif()

if(NOT COMMAND default_package_version)
  include(DefaultPackageVersion)
endif()

if(NOT COMMAND upstream_ver_from_package_ver)
  include(UpstreamVerFromPackageVer)
endif()

# set_default_SDL_versions(SDL_version_major)
#   queries system package manager to get default versions of the SDL core and
#   extension packages, setting the following variables in <major>.<minor>.<micro>
#   format:
#     SDL_DEFAULT_VERSION
#     SDL_IMAGE_DEFAULT_VERSION
#     SDL_MIXER_DEFAULT_VERSION
#     SDL_NET_DEFAULT_VERSION
#     SDL_RTF_DEFAULT_VERSION
#     SDL_TTF_DEFAULT_VERSION
#
#   SDL_version_major (string): major version of SDL to search for
#
macro(set_default_SDL_versions SDL_version_major)
  if(NOT ${SDL_version_major} EQUAL 1 AND
      NOT ${SDL_version_major} EQUAL 2)
    message(WARNING "unrecognized SDL major version, expected 1 or 2, got \
\"${SDL_version_major}\"")
  endif()

  # sets PACKAGE_MANAGER_BINARY if not already cached
  determine_package_manager()

  foreach(version_var
      SDL_DEFAULT_VERSION
      SDL_IMAGE_DEFAULT_VERSION
      SDL_MIXER_DEFAULT_VERSION
      SDL_NET_DEFAULT_VERSION
      SDL_RTF_DEFAULT_VERSION
      SDL_TTF_DEFAULT_VERSION
    )
    unset(${version_var})
  endforeach()

  if(${PACKAGE_MANAGER_BINARY} MATCHES "/brew$")
    #
    # MacOS: homebrew
    #
    if(${SDL_version_major} EQUAL 1)
      default_package_version("sdl12-compat" SDL_DEFAULT_VERSION)
      default_package_version("sdl_image"    SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("sdl_mixer"    SDL_MIXER_DEFAULT_VERSION)
      default_package_version("sdl_net"      SDL_NET_DEFAULT_VERSION)
      default_package_version(" "            SDL_RTF_DEFAULT_VERSION)
      default_package_version("sdl_ttf"      SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("sdl2"         SDL_DEFAULT_VERSION)
      default_package_version("sdl2_image"   SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("sdl2_mixer"   SDL_MIXER_DEFAULT_VERSION)
      default_package_version("sdl2_net"     SDL_NET_DEFAULT_VERSION)
      default_package_version(" "            SDL_RTF_DEFAULT_VERSION)
      default_package_version("sdl2_ttf"     SDL_TTF_DEFAULT_VERSION)
    endif()
  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/aptitude$" OR
      ${PACKAGE_MANAGER_BINARY} MATCHES "/apt$")
    #
    # Debian: aptitude > apt [> dpkg]
    #
    if(${SDL_version_major} EQUAL 1)
      default_package_version("libsdl1.2-compat"    SDL_DEFAULT_VERSION)
      default_package_version("libsdl-image1.2"     SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("libsdl-mixer1.2"     SDL_MIXER_DEFAULT_VERSION)
      default_package_version("libsdl-net1.2"       SDL_NET_DEFAULT_VERSION)
      default_package_version(" "                   SDL_RTF_DEFAULT_VERSION)
      default_package_version(" "                   SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("libsdl2-2.0-0"       SDL_DEFAULT_VERSION)
      default_package_version("libsdl2-image-2.0-0" SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("libsdl2-mixer-2.0-0" SDL_MIXER_DEFAULT_VERSION)
      default_package_version("libsdl2-net-2.0-0"   SDL_NET_DEFAULT_VERSION)
      default_package_version(" "                   SDL_RTF_DEFAULT_VERSION)
      default_package_version("libsdl2-ttf-2.0-0"   SDL_TTF_DEFAULT_VERSION)
    endif()
  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/dnf$" OR
      ${PACKAGE_MANAGER_BINARY} MATCHES "/yum$")
    #
    # RHEL: dnf > yum [> rpm]
    #
    if(${SDL_version_major} EQUAL 1)
      default_package_version(" "          SDL_DEFAULT_VERSION)
      default_package_version("SDL_image"  SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("SDL_mixer"  SDL_MIXER_DEFAULT_VERSION)
      default_package_version("SDL_net"    SDL_NET_DEFAULT_VERSION)
      default_package_version(" "          SDL_RTF_DEFAULT_VERSION)
      default_package_version("SDL_ttf"    SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("SDL2"       SDL_DEFAULT_VERSION)
      default_package_version("SDL2_image" SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("SDL2_mixer" SDL_MIXER_DEFAULT_VERSION)
      default_package_version("SDL2_net"   SDL_NET_DEFAULT_VERSION)
      default_package_version(" "          SDL_RTF_DEFAULT_VERSION)
      default_package_version("SDL2_ttf"   SDL_TTF_DEFAULT_VERSION)
    endif()
  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/pacman$")
    #
    # Arch: pacman
    #
    if(${SDL_version_major} EQUAL 1)
      default_package_version("sdl12-compat" SDL_DEFAULT_VERSION)
      default_package_version("sdl_image"    SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("sdl_mixer"    SDL_MIXER_DEFAULT_VERSION)
      default_package_version("sdl_net"      SDL_NET_DEFAULT_VERSION)
      default_package_version(" "            SDL_RTF_DEFAULT_VERSION)
      default_package_version("sdl_ttf"      SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("sdl2"         SDL_DEFAULT_VERSION)
      default_package_version("sdl2_image"   SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("sdl2_mixer"   SDL_MIXER_DEFAULT_VERSION)
      default_package_version("sdl2_net"     SDL_NET_DEFAULT_VERSION)
      default_package_version(" "            SDL_RTF_DEFAULT_VERSION)
      default_package_version("sdl2_ttf"     SDL_TTF_DEFAULT_VERSION)
    endif()
  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/emerge")
    #
    # Gentoo: portage (emerge)
    #
    if(${SDL_version_major} EQUAL 1)
      default_package_version("libsdl"     SDL_DEFAULT_VERSION)
      default_package_version(" "          SDL_IMAGE_DEFAULT_VERSION)
      default_package_version(" "          SDL_MIXER_DEFAULT_VERSION)
      default_package_version(" "          SDL_NET_DEFAULT_VERSION)
      default_package_version(" "          SDL_RTF_DEFAULT_VERSION)
      default_package_version(" "          SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("libsdl2"    SDL_DEFAULT_VERSION)
      default_package_version("sdl2-image" SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("sdl2-mixer" SDL_MIXER_DEFAULT_VERSION)
      default_package_version("sdl2-net"   SDL_NET_DEFAULT_VERSION)
      default_package_version("sdl2-rtf"   SDL_RTF_DEFAULT_VERSION)
      default_package_version("sdl2-ttf"   SDL_TTF_DEFAULT_VERSION)
    endif()
  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/zypper$")
    #
    # openSUSE: zypper [> rpm]
    #
    # note: passing "" to `zypper info` will list all packages
    if(${SDL_version_major} EQUAL 1)
      default_package_version("libSDL-1_2-0"        SDL_DEFAULT_VERSION)
      default_package_version("libSDL_image-1_2-0"  SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("libSDL_mixer-1_2-0"  SDL_MIXER_DEFAULT_VERSION)
      default_package_version("libSDL_net-1_2-0"    SDL_NET_DEFAULT_VERSION)
      default_package_version(" "                   SDL_RTF_DEFAULT_VERSION)
      default_package_version("libSDL_ttf-1_2-0"    SDL_TTF_DEFAULT_VERSION)
    elseif(${SDL_version_major} EQUAL 2)
      default_package_version("libSDL2-2_0-0"       SDL_DEFAULT_VERSION)
      default_package_version("libSDL2_image-2_0-0" SDL_IMAGE_DEFAULT_VERSION)
      default_package_version("libSDL2_mixer-2_0-0" SDL_MIXER_DEFAULT_VERSION)
      default_package_version("libSDL2_net-2_0-0"   SDL_NET_DEFAULT_VERSION)
      default_package_version(" "                   SDL_RTF_DEFAULT_VERSION)
      default_package_version("libSDL2_ttf-2_0-0"   SDL_TTF_DEFAULT_VERSION)
    endif()
  else()
    message(WARNING "`${PACKAGE_MANAGER_BINARY}` is unsupported package manager")
  endif()

  macro(SDL_version_from_package_version package_ver SDL_ver_var)
    upstream_ver_from_package_ver(${package_ver} ${SDL_ver_var})
    # upstream version according to package manager may still have suffixes,
    #    eg "+dfsg" or "+hg695". Here we strip all else away to get the
    #    <major>.<minor>.<micro> version used by SDL repository tags.
    # (double backslashes for cmake argument parsing)
    string(REGEX REPLACE
      "^([0-9]+\\.[0-9]+\\.[0-9]+).*$" "\\1"
      ${SDL_ver_var} ${${SDL_ver_var}})
  endmacro()

  foreach(version_var
      SDL_DEFAULT_VERSION
      SDL_IMAGE_DEFAULT_VERSION
      SDL_MIXER_DEFAULT_VERSION
      SDL_NET_DEFAULT_VERSION
      SDL_RTF_DEFAULT_VERSION
      SDL_TTF_DEFAULT_VERSION
    )
    if(${version_var})
      SDL_version_from_package_version(${${version_var}} ${version_var})
    endif()
  endforeach()

endmacro()
