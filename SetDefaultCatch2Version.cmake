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

# set_default_catch2_version()
#   queries system package manager to get default version of the Catch2 library,
#     setting CATCH_DEFAULT_VERSION in <major>.<minor>.<patch> format
#
macro(set_default_catch2_version)
  # sets PACKAGE_MANAGER_BINARY if not already cached
  determine_package_manager()

  unset(CATCH_DEFAULT_VERSION)

  if(${PACKAGE_MANAGER_BINARY} MATCHES "/brew$")
    # MacOS: homebrew
    default_package_version("catch2" CATCH_DEFAULT_VERSION)

  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/aptitude$" OR
      ${PACKAGE_MANAGER_BINARY} MATCHES "/apt$")
    # Debian: aptitude > apt [> dpkg]
    default_package_version("catch2" CATCH_DEFAULT_VERSION)

  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/dnf$" OR
      ${PACKAGE_MANAGER_BINARY} MATCHES "/yum$")
    # RHEL: dnf > yum [> rpm]
    default_package_version("catch"  CATCH_DEFAULT_VERSION)

  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/pacman$")
    # Arch: pacman
    default_package_version("catch2" CATCH_DEFAULT_VERSION)

  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/emerge")
    # Gentoo: portage (emerge)
    default_package_version("catch"  CATCH_DEFAULT_VERSION)

  elseif(${PACKAGE_MANAGER_BINARY} MATCHES "/zypper$")
    # openSUSE: zypper [> rpm]
    # note: passing "" to `zypper info` will list all packages
    default_package_version("Catch2" CATCH_DEFAULT_VERSION)

  else()
    message(WARNING "`${PACKAGE_MANAGER_BINARY}` is unsupported package manager")
  endif()

  if(${CATCH_DEFAULT_VERSION})
    upstream_ver_from_package_ver(
      "${CATCH_DEFAULT_VERSION}" CATCH_DEFAULT_VERSION)
    # upstream version according to package manager may still have suffixes,
    #    eg "+dfsg" or "+hg695". Here we strip all else away to get the
    #    <major>.<minor>.<patch> version used by Catch2 repository tags.
    # (double backslashes for cmake argument parsing)
    string(REGEX REPLACE
      "^([0-9]+\\.[0-9]+\\.[0-9]+).*$" "\\1"
      CATCH_DEFAULT_VERSION "${CATCH_DEFAULT_VERSION}")
  endif()

endmacro()
