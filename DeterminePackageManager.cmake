cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# determine_package_manager()
#   sets cache variable PACKAGE_MANAGER_BINARY to full path of first executable
#     found in the following order of preference:
#     - MacOS/OSX: homebrew
#     - Debian: aptitude > apt [> dpkg]
#     - RHEL: dnf > yum [> rpm]
#     - Arch: pacman
#     - Gentoo: portage (emerge)
#     - openSUSE: zypper
#
#   For comparison of package managers, see:
#     - https://www.tecmint.com/linux-package-managers/
#     - https://wiki.archlinux.org/title/Pacman_Rosetta
#
function(determine_package_manager)
  if(PACKAGE_MANAGER_BINARY)
    return()
  endif()

  #
  # MacOS/OSX: homebrew
  #
  # APPLE includes iOS - must test for Darwin instead
  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    find_program(BREW_BINARY
      brew
    )
    if(BREW_BINARY)
      set(PACKAGE_MANAGER_BINARY ${BREW_BINARY} CACHE FILEPATH
      "full path to brew (homebrew) executable")
    endif()
    return()
  endif()

  # LINUX not introduced until cmake v3.25
  if(NOT ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    message(WARNING "determine_package_manager() only currently supports Linux \
and MacOS/OSX systems")
    return()
  endif()

  #
  # Debian: aptitude > dpkg > apt (last due to unstable CLI interface)
  #
  find_program(APTITUDE_BINARY
    aptitude
  )
  if(APTITUDE_BINARY)
    set(PACKAGE_MANAGER_BINARY ${APTITUDE_BINARY} CACHE FILEPATH
      "full path to aptitude executable")
    return()
  endif()

  find_program(APT_BINARY
    apt
  )
  if(APT_BINARY)
    set(PACKAGE_MANAGER_BINARY ${APT_BINARY} CACHE FILEPATH
      "full path to apt executable")
    return()
  endif()

  # dpkg can only query installed packages or .deb files, see:
  #   https://www.debian.org/doc/manuals/debian-handbook/sect.manipulating-packages-with-dpkg.en.html
  #   https://www.man7.org/linux/man-pages/man1/dpkg.1.html

  #
  # RHEL: dnf > yum [> rpm]
  #
  find_program(DNF_BINARY
    dnf
  )
  if(DNF_BINARY)
    set(PACKAGE_MANAGER_BINARY ${DNF_BINARY} CACHE FILEPATH
      "full path to dnf executable")
    return()
  endif()

  find_program(YUM_BINARY
    yum
  )
  if(YUM_BINARY)
    set(PACKAGE_MANAGER_BINARY ${YUM_BINARY} CACHE FILEPATH
      "full path to yum executable")
    return()
  endif()

  # Seems that much like dpkg, rpm can only query installed packages or .rpm files, see:
  #   https://www.man7.org/linux/man-pages/man8/rpm.8.html
  #   https://unix.stackexchange.com/questions/6864/how-to-search-for-official-rhel-packages

  #
  # Arch: pacman
  #
  find_program(PACMAN_BINARY
    pacman
  )
  if(PACMAN_BINARY)
    set(PACKAGE_MANAGER_BINARY ${PACMAN_BINARY} CACHE FILEPATH
      "full path to pacman executable")
    return()
  endif()

  #
  # Gentoo: portage (emerge)
  #
  find_program(EMERGE_BINARY
    emerge
  )
  if(EMERGE_BINARY)
    set(PACKAGE_MANAGER_BINARY ${EMERGE_BINARY} CACHE FILEPATH
      "full path to emerge (portage) executable")
    return()
  endif()

  #
  # openSUSE: zypper [> rpm]
  #
  find_program(ZYPPER_BINARY
    zypper
  )
  if(ZYPPER_BINARY)
    set(PACKAGE_MANAGER_BINARY ${ZYPPER_BINARY} CACHE FILEPATH
      "full path to zypper executable")
    return()
  endif()

endfunction()
