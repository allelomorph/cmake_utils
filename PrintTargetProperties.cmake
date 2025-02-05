# TBD re-evaluate supported versions, string(JOIN) v3.12, if(CACHE{}) v3.14
cmake_minimum_required(VERSION 3.14)

include_guard(DIRECTORY)

# set_cmake_property_lists()
#   Caches lists of potential target properties for targets from parsing
#     `cmake --help-property-list`, setting the following variables:
#     - CMAKE_NO_INFIX_PROPERTY_LIST
#     - CMAKE_CONFIG_INFIX_PROPERTY_LIST
#     - CMAKE_LANG_INFIX_PROPERTY_LIST
#     - CMAKE_NAME_INFIX_PROPERTY_LIST
#     - CMAKE_OTHER_INFIX_PROPERTY_LIST
#     - CMAKE_UNREADABLE_PROPERTIES
#
#   For versions of cmake below 3.19, calling get_target_property() on
#     INTERFACE targets with non-whitelisted properties will throw errors, see:
#     - https://cmake.org/cmake/help/v3.18/manual/cmake-buildsystem.7.html#interface-libraries
#     - https://discourse.cmake.org/t/how-to-find-current-interface-library-property-whitelist/4784/2
#   In that case, additional variables are cached:
#     - CMAKE_NO_INFIX_PROPERTY_WHITELIST
#     - CMAKE_CONFIG_INFIX_PROPERTY_WHITELIST
#
#   Originally based on these solutions:
#     - https://stackoverflow.com/a/34292622
#     - https://stackoverflow.com/a/74215868
#
function(set_cmake_property_lists)
  set(need_to_set_lists FALSE)
  if(NOT DEFINED CACHE{CMAKE_NO_INFIX_PROPERTY_LIST} OR
      NOT DEFINED CACHE{CMAKE_CONFIG_INFIX_PROPERTY_LIST} OR
      NOT DEFINED CACHE{CMAKE_LANG_INFIX_PROPERTY_LIST} OR
      NOT DEFINED CACHE{CMAKE_NAME_INFIX_PROPERTY_LIST} OR
      NOT DEFINED CACHE{CMAKE_OTHER_INFIX_PROPERTY_LIST}
    )
    set(need_to_set_lists TRUE)
  endif()

  set(need_to_set_whitelists FALSE)
  if(CMAKE_VERSION VERSION_LESS "3.19" AND
      (NOT DEFINED CACHE{CMAKE_NO_INFIX_PROPERTY_WHITELIST} OR
        NOT DEFINED CACHE{CMAKE_CONFIG_INFIX_PROPERTY_WHITELIST})
    )
    set(need_to_set_whitelists TRUE)
  endif()

  if(NOT (need_to_set_lists OR need_to_set_whitelists))
    return()
  endif()

  # Get all propreties supported by current cmake version
  #   (note that this will be a mixed list of GLOBAL, DIRECTORY, TARGET, SOURCE,
  #   INSTALL, TEST, CACHE properties)
  execute_process(
    COMMAND cmake --help-property-list
    OUTPUT_VARIABLE help_property_list
  )
  # Convert output to list
  string(REGEX REPLACE ";" "\\\\;" help_property_list "${help_property_list}")
  string(REGEX REPLACE "\n" ";" help_property_list "${help_property_list}")
  # output should already be sorted and unique, but cleaning anyway
  list(REMOVE_DUPLICATES help_property_list)
  list(SORT help_property_list)

  # Directly reading LOCATION property violates CMP0026, see:
  #   - https://stackoverflow.com/a/58244245
  #   - https://stackoverflow.com/q/32197663
  # Producing errors such as:
  #   "The LOCATION property may not be read from target "<target>".  Use the
  #   target name directly with add_custom_command, or use the generator
  #   expression $<TARGET_FILE>, as appropriate."
  # If config-time reading of LOCATION is still only deprecated and not disabled,
  #   one could use `cmake_policy(PUSH) cmake_policy(SET CMP0026 OLD)` before
  #   and `cmake_policy(POP)` after calls to get_target_property, although this
  #   will emit warnings
  set(unreadable_location_properties
    # IMPORTED_LOCATION  # no error
    LOCATION
    LOCATION_<CONFIG>
    MACOSX_PACKAGE_LOCATION
    VS_DEPLOYMENT_LOCATION
  )

  if(need_to_set_lists)
    set(property_list ${help_property_list})

    set(config_property_list ${property_list})
    list(FILTER config_property_list INCLUDE REGEX "<CONFIG>")
    list(FILTER property_list EXCLUDE REGEX "<CONFIG>")

    set(lang_property_list ${property_list})
    list(FILTER lang_property_list INCLUDE REGEX "<LANG>")
    list(FILTER property_list EXCLUDE REGEX "<LANG>")

    set(name_property_list ${property_list})
    list(FILTER name_property_list INCLUDE REGEX "<NAME>")
    list(FILTER property_list EXCLUDE REGEX "<NAME>")

    set(other_infix_property_list ${property_list})
    list(FILTER other_infix_property_list INCLUDE REGEX "<[A-Za-z]+>")
    list(FILTER property_list EXCLUDE REGEX "<[A-Za-z]+>")

    set(CMAKE_NO_INFIX_PROPERTY_LIST "${property_list}"
      CACHE STRING
      "potential properties for this version of cmake with no <> infix"
      FORCE)
    set(CMAKE_CONFIG_INFIX_PROPERTY_LIST "${config_property_list}"
      CACHE STRING
      "potential properties for this version of cmake with <CONFIG> infix"
      FORCE)
    set(CMAKE_LANG_INFIX_PROPERTY_LIST "${lang_property_list}"
      CACHE STRING
      "potential properties for this version of cmake with <LANG> infix"
      FORCE)
    set(CMAKE_NAME_INFIX_PROPERTY_LIST "${name_property_list}"
      CACHE STRING
      "potential properties for this version of cmake with <NAME> infix"
      FORCE)
    # TBD Other property wildcards ignored for now, eg:
    # - LIBRARY       eg LINK_LIBRARY_OVERRIDE_<LIBRARY>
    # - refname       eg VS_DOTNET_REFERENCE_<refname>,
    #                    VS_DOTNET_REFERENCEPROP_<refname>_TAG_<tagname>
    # - tool          eg VS_SOURCE_SETTINGS_<tool>
    # - type          eg XCODE_EMBED_<type>;XCODE_EMBED_<type>_CODE_SIGN_ON_COPY;
    #                    XCODE_EMBED_<type>_PATH;XCODE_EMBED_<type>_REMOVE_HEADERS_ON_COPY
    # - variable      eg VS_GLOBAL_<variable>
    set(CMAKE_OTHER_INFIX_PROPERTY_LIST "${other_infix_property_list}"
      CACHE STRING
      "potential properties for this version of cmake with <> infixes /
other than CONFIG, LANG, or NAME"
      FORCE)
    set(CMAKE_UNREADABLE_PROPERTIES "${unreadable_location_properties}"
      CACHE STRING
      "properties which are unreadable at config time (eg LOCATION) - consider
using genex alternatives"
      FORCE
    )
    mark_as_advanced(FORCE
      CMAKE_NO_INFIX_PROPERTY_LIST
      CMAKE_CONFIG_INFIX_PROPERTY_LIST
      CMAKE_LANG_INFIX_PROPERTY_LIST
      CMAKE_NAME_INFIX_PROPERTY_LIST
      CMAKE_OTHER_INFIX_PROPERTY_LIST
      CMAKE_UNREADABLE_PROPERTIES
    )

  endif()

  if(need_to_set_whitelists)
    set(property_whitelist ${help_property_list})
    # all regex items but NO_SYSTEM_FROM_IMPORTED and TYPE dervied from:
    #  - https://cmake.org/cmake/help/v3.18/manual/cmake-buildsystem.7.html#interface-libraries
    string(JOIN "" whitelist_regex
      "^("
      "COMPATIBLE_INTERFACE_.+|"
      "EXPORT_NAME|"
      "EXPORT_PROPERTIES|"
      "IMPORTED|"
      "IMPORTED_LIBNAME_.+|"
      "INTERFACE_.+|"
      "MANUALLY_ADDED_DEPENDENCIES|"
      "MAP_IMPORTED_CONFIG_.+|"
      "NAME|"
      "NO_SYSTEM_FROM_IMPORTED|"
      "TYPE"
      ")$")
    list(FILTER property_whitelist INCLUDE REGEX "${whitelist_regex}")

    # only expecting <CONFIG> infixes after above filter
    set(config_property_whitelist ${property_whitelist})
    list(FILTER config_property_whitelist INCLUDE REGEX "<CONFIG>")
    list(FILTER property_whitelist EXCLUDE REGEX "<CONFIG>")

    set(CMAKE_NO_INFIX_PROPERTY_WHITELIST "${property_whitelist}"
      CACHE STRING
      "potential INTERFACE target properties for this version of cmake with /
no <> infix that are whitelisted for get_target_property()"
      FORCE)
    set(CMAKE_CONFIG_INFIX_PROPERTY_WHITELIST "${config_property_whitelist}"
      CACHE STRING
      "potential INTERFACE target properties for this version of cmake with /
<CONFIG> infix that are whitelisted for get_target_property()"
      FORCE)
    mark_as_advanced(FORCE
      CMAKE_NO_INFIX_PROPERTY_WHITELIST
      CMAKE_CONFIG_INFIX_PROPERTY_WHITELIST
    )
  endif()

endfunction()

# print_target_properties(target)
#   debug print of all set properties values for a given target
#
#   target (string): target to test
#
function(print_target_properties target)
  if(NOT TARGET ${target})
    return()
  endif()

  # idempotent
  set_cmake_property_lists()

  set(whitelist_only FALSE)
  get_target_property(target_type ${target} TYPE)
  if(CMAKE_VERSION VERSION_LESS "3.19" AND
      "${target_type}" STREQUAL "INTERFACE")
    set(whitelist_only TRUE)
  endif()

  if(whitelist_only)
    set(properties        ${CMAKE_NO_INFIX_PROPERTY_WHITELIST})
    set(config_properties ${CMAKE_CONFIG_INFIX_PROPERTY_WHITELIST})
  else()
    set(properties        ${CMAKE_NO_INFIX_PROPERTY_LIST})
    set(config_properties ${CMAKE_CONFIG_INFIX_PROPERTY_LIST})
    set(lang_properties   ${CMAKE_LANG_INFIX_PROPERTY_LIST})
    set(name_properties   ${CMAKE_NAME_INFIX_PROPERTY_LIST})
  endif()

  list(JOIN CMAKE_UNREADABLE_PROPERTIES "|" unreadable_prop_regex)
  string(PREPEND unreadable_prop_regex "^(")
  string(APPEND unreadable_prop_regex ")$")
  list(FILTER properties EXCLUDE REGEX "${unreadable_prop_regex}")

  # populate "<CONFIG>" infix with any defined config types
  set(available_configs ${CMAKE_CONFIGURATION_TYPES})
  if(NOT ${CMAKE_BUILD_TYPE} IN_LIST available_configs)
    list(APPEND available_configs ${CMAKE_BUILD_TYPE})
  endif()
  foreach(config_prop IN LISTS config_properties)
    if(NOT ${config_prop} IN_LIST CMAKE_UNREADABLE_PROPERTIES)
      foreach(config IN LISTS available_configs)
        string(TOUPPER "${config}" config)
        string(REPLACE "<CONFIG>" "${config}" infixed_prop "${config_prop}")
        list(APPEND properties ${infixed_prop})
      endforeach()
    endif()
  endforeach()

  if(NOT whitelist_only)
    # populate "<LANG>" infix with any defined target languages
    get_target_property(target_lang ${target} LANGUAGE)
    if(target_lang)
      foreach(lang_prop IN LISTS lang_properties)
        if(NOT ${lang_prop} IN_LIST CMAKE_UNREADABLE_PROPERTIES)
          string(REPLACE "<LANG>" "${target_lang}" infixed_prop "${lang_prop}")
          list(APPEND properties ${infixed_prop})
        endif()
      endforeach()
    endif()

    # populate "<NAME>" infix with target name
    get_target_property(target_name ${target} NAME)
    if(target_name)
      foreach(name_prop IN LISTS name_properties)
        if(NOT ${name_prop} IN_LIST CMAKE_UNREADABLE_PROPERTIES)
          string(REPLACE "<NAME>" "${target_name}" infixed_prop "${name_prop}")
          list(APPEND properties ${infixed_prop})
        endif()
      endforeach()
    endif()
  endif(NOT whitelist_only)

  message("Properties of target ${target}:")
  foreach(property ${properties})
    get_target_property(value ${target} ${property})
    if(NOT value MATCHES "NOTFOUND$")
      message("    ${property}: ${value}")
    endif()
  endforeach()

endfunction()
