cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

if(NOT COMMAND determine_package_manager)
  include(DeterminePackageManager)
endif()


# default_package_version(package package_ver_var)
#   sets package_ver_var to default version of package supplied by system
#   package manager, or ${package_ver_var}-NOTFOUND if not available:
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
#   package (string): name of package to search
#   package_ver_var (string): variable in parent scope to store version
#
function(default_package_version package package_ver_var)

  # LINUX not introduced until cmake v3.25; APPLE includes iOS, etc.
  if(NOT ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux" AND
      NOT ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    message(WARNING "default_package_version() only currently supports Linux and MacOS/OSX systems")
    # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  #
  # establish text parsing commands
  #
  find_program(AWK_BINARY
    awk
  )
  if(NOT AWK_BINARY)
    message(WARNING "default_package_version could not find system `awk` binary")
    # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  find_program(GREP_BINARY
    grep
  )
  if(NOT GREP_BINARY)
    message(WARNING "default_package_version could not find system `grep` binary")
    # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  find_program(HEAD_BINARY
    head
  )
  if(NOT HEAD_BINARY)
    message(WARNING "default_package_version could not find system `head` binary")
    # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  find_program(SORT_BINARY
    sort
  )
  if(NOT SORT_BINARY)
    message(WARNING "default_package_version could not find system `sort` binary")
    # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  # sets PACKAGE_MANAGER_BINARY if not already cached
  determine_package_manager()

  #
  # MacOS: homebrew
  #
  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    if(NOT ${PACKAGE_MANAGER_BINARY} MATCHES "/brew$")
      message(WARNING "default_package_version() requires homebrew for MacOS/OSX")
      set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
      return()
    endif()
    if(${CMAKE_VERSION} VERSION_LESS "3.19")
      message(WARNING "default_package_version() requires cmake 3.19 or greater \
for JSON string parsing (of homebrew output)")
      # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
      return()
    endif()

    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} info --json "${package}"
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT
    )
    if(CMD_OUTPUT)
      string(JSON JSON_PKG_INFO
        ERROR_VARIABLE JSON_ERR
        GET ${CMD_OUTPUT} 0
      )
      if(JSON_ERR)
        message(WARNING
          [=[default_package_version() homebrew JSON output parsing failure:
            ${JSON_ERR}
]=])
        # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
        return()
      endif()
      string(JSON JSON_PKG_VERSIONS
        ERROR_VARIABLE JSON_ERR
        GET ${JSON_PKG_INFO} "versions"
      )
      if(JSON_ERR)
        message(WARNING
          [=[default_package_version() homebrew JSON output parsing failure:
            ${JSON_ERR}
]=])
        # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
        return()
      endif()
      string(JSON STABLE_VERSION
        ERROR_VARIABLE JSON_ERR
        GET ${JSON_PKG_VERSIONS} "stable"
      )
      if(JSON_ERR)
        message(WARNING
          [=[default_package_version() homebrew JSON output parsing failure:
            ${JSON_ERR}
]=])
        # set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
        return()
      endif()
      set(${package_ver_var} ${STABLE_VERSION} PARENT_SCOPE)
      return()
    endif()  # CMD_OUTPUT
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()  # MacOS/OSX

  #
  # Debian: aptitude > apt [> dpkg]
  #
  if(${PACKAGE_MANAGER_BINARY} MATCHES "/aptitude$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} search --display-format "%V" "^${package}$"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  if(${PACKAGE_MANAGER_BINARY} MATCHES "/apt$")
    # 'WARNING: apt does not have a stable CLI interface. Use with caution in scripts.'
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} list "~n^${package}$"
      COMMAND ${GREP_BINARY} -E "^${package}/"
      COMMAND ${AWK_BINARY} "{print $2}"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  # dpkg can only query installed packages or .deb files, see:
  #   https://www.debian.org/doc/manuals/debian-handbook/sect.manipulating-packages-with-dpkg.en.html
  #   https://www.man7.org/linux/man-pages/man1/dpkg.1.html

  #
  # RHEL: dnf > yum [> rpm]
  #
  if(${PACKAGE_MANAGER_BINARY} MATCHES "/dnf$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} list "${package}"
      COMMAND ${GREP_BINARY} -E "^${package}\."
      COMMAND ${AWK_BINARY} "{print $2}"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  if(${PACKAGE_MANAGER_BINARY} MATCHES "/yum$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} list "${package}"
      COMMAND ${GREP_BINARY} -E "^${package}\."
      COMMAND ${AWK_BINARY} '{print $2}'
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  # Seems that much like dpkg, rpm can only query installed packages or .rpm files, see:
  #   https://www.man7.org/linux/man-pages/man8/rpm.8.html
  #   https://unix.stackexchange.com/questions/6864/how-to-search-for-official-rhel-packages

  #
  # Arch: pacman
  #
  if(${PACKAGE_MANAGER_BINARY} MATCHES "/pacman$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} --sync --search "^${package}$"
      COMMAND ${GREP_BINARY} -E "/${package} "
      COMMAND ${AWK_BINARY} "{print $2}"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  #
  # Gentoo: portage (emerge)
  #
  # `emerge --pretend --quiet --columns "${package}"` has more stable, parseable
  #    output, but may ignore --quiet/--columns if it fails due to circular
  #    dependency, which breaks parsing
  if(${PACKAGE_MANAGER_BINARY} MATCHES "/emerge$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} --search "%^${package}$"
      COMMAND ${GREP_BINARY} "Latest version available: "
      COMMAND ${AWK_BINARY} "{print $4}"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

  #
  # openSUSE: zypper [> rpm]
  #
  if(${PACKAGE_MANAGER_BINARY} MATCHES "/zypper$")
    execute_process(
      COMMAND ${PACKAGE_MANAGER_BINARY} info "${package}"
      COMMAND ${GREP_BINARY} -E "^Version "
      COMMAND ${AWK_BINARY} "{print $3}"
      COMMAND ${SORT_BINARY} -Vr
      COMMAND ${HEAD_BINARY} -n1
      ERROR_FILE /dev/null
      OUTPUT_VARIABLE CMD_OUTPUT_LINE
    )
    if(CMD_OUTPUT_LINE)
      string(STRIP ${CMD_OUTPUT_LINE} CMD_OUTPUT)  # remove trailing newline
      set(${package_ver_var} ${CMD_OUTPUT} PARENT_SCOPE)
      return()
    endif()
    set(${package_ver_var} "${package_ver_var}-NOTFOUND" PARENT_SCOPE)
    return()
  endif()

endfunction()
