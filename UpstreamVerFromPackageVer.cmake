cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

# upstream_ver_from_package_ver(package_ver upstream_ver_var)
#   strips prefixes and suffixes from a package version to get the upstream
#   version number
#
#   Looking first at Debian package versioning, see:
#     - https://manpages.ubuntu.com/manpages/trusty/man5/deb-version.5.html
#   gives us a scheme of:
#     [epoch:]upstream-version[-debian-revision]
#   where the upstream-version only contains a ':' if the epoch is present, and
#   a '-' if the debian-revision is present. So, we can remove the first colon
#   and everything before it, and the last hypen and everything after it.
#
#   Examples for other package managers seem to indicate this pattern can be
#   extrapolated to other Linux package managers, see:
#     - https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/
#     - https://docs.pagure.org/fedora-infra.rpmautospec/autorelease.html
#     - https://wiki.archlinux.org/title/Arch_package_guidelines#Package_versioning
#     - https://wiki.gentoo.org/wiki/Version_specifier
#
#   package_ver (string): package version number
#   upstream_ver_var (string): variable to store upstream version number
#
macro(upstream_ver_from_package_ver package_ver upstream_ver_var)

  # strip epoch (prefix ending in first ':')
  string(FIND "${package_ver}" ":" I)
  if(NOT ${I} EQUAL -1)
    math(EXPR I "${I} + 1")
    string(SUBSTRING "${package_ver}" ${I} -1 ${upstream_ver_var})
  endif()

  # strip revision (suffix beginning at last '-')
  string(FIND "${${upstream_ver_var}}" "-" I REVERSE)
  if(NOT ${I} EQUAL -1)
    string(SUBSTRING "${${upstream_ver_var}}" 0 ${I} ${upstream_ver_var})
  endif()

endmacro()
