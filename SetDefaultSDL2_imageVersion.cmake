# include(SetDefaultSDL2_imageVersion)
#   queries system package manager to get default version of SDL2_image library,
#     caching SDL2_IMAGE_DEFAULT_VERSION in <major>.<minor>.<patch> format

# newest feature used: if(DEFINED CACHE{}) v3.14
cmake_minimum_required(VERSION 3.14)

include_guard(DIRECTORY)

if(DEFINED CACHE{SDL2_IMAGE_DEFAULT_VERSION})
  return()
endif()

if(NOT COMMAND determine_package_manager)
  include(DeterminePackageManager)
endif()

if(NOT COMMAND default_package_version)
  include(DefaultPackageVersion)
endif()

if(NOT COMMAND upstream_ver_from_package_ver)
  include(UpstreamVerFromPackageVer)
endif()

if(NOT PACKAGE_MANAGER_BINARY)
  determine_package_manager()
endif()

unset(_SDL2_IMAGE_DEFAULT_VERSION)

if(${PACKAGE_MANAGER_BINARY} MATCHES "/brew$")

  # MacOS: homebrew
  default_package_version("sdl2_image"          _SDL2_IMAGE_DEFAULT_VERSION)

elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/aptitude$" OR
    ${PACKAGE_MANAGER_BINARY} MATCHES "/apt$")

  # Debian: aptitude > apt [> dpkg]
  default_package_version("libsdl2-image-2.0-0" _SDL2_IMAGE_DEFAULT_VERSION)

elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/dnf$" OR
    ${PACKAGE_MANAGER_BINARY} MATCHES "/yum$")

  # RHEL: dnf > yum [> rpm]
  default_package_version("SDL2_image"          _SDL2_IMAGE_DEFAULT_VERSION)

elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/pacman$")

  # Arch: pacman
  default_package_version("sdl2_image"          _SDL2_IMAGE_DEFAULT_VERSION)

elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/emerge")

  # Gentoo: portage (emerge)
  default_package_version("sdl2-image"          _SDL2_IMAGE_DEFAULT_VERSION)

elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/zypper$")

  # openSUSE: zypper [> rpm]
  # note: passing "" to `zypper info` will list all packages
  default_package_version("libSDL2_image-2_0-0" _SDL2_IMAGE_DEFAULT_VERSION)

else()
  message(WARNING "`${PACKAGE_MANAGER_BINARY}` is unsupported package manager")
endif()

if(NOT ${_SDL2_IMAGE_DEFAULT_VERSION} MATCHES "-NOTFOUND$")
  upstream_ver_from_package_ver(
    "${_SDL2_IMAGE_DEFAULT_VERSION}" _SDL2_IMAGE_DEFAULT_VERSION)
  # upstream version according to package manager may still have suffixes,
  #    eg "+dfsg" or "+hg695". Here we strip all else away to get the
  #    <major>.<minor>.<patch> version used by Catch2 repository tags.
  # (double backslashes for cmake argument parsing)
  string(REGEX REPLACE
    "^([0-9]+\\.[0-9]+\\.[0-9]+).*$" "\\1"
    _SDL2_IMAGE_DEFAULT_VERSION "${_SDL2_IMAGE_DEFAULT_VERSION}")
endif()

set(SDL2_IMAGE_DEFAULT_VERSION "${_SDL2_IMAGE_DEFAULT_VERSION}" CACHE STRING
  "default SDL2_image package version in <major>.<minor>.<patch> format")
unset(_SDL2_IMAGE_DEFAULT_VERSION)
