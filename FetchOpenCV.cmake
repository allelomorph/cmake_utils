cmake_minimum_required(VERSION 3.10)

include_guard(DIRECTORY)

if(NOT COMMAND FetchContent_Declare OR
   NOT COMMAND FetchContent_MakeAvailable)
  include(FetchContent)
endif()

find_file(DEBIAN_VERSION_FILE
  debian_version
  PATHS /etc/
  NO_DEFAULT_PATH
)
find_program(APT_BINARY
  apt
)
find_program(APT_CACHE_BINARY
  apt-cache
)
find_program(AWK_BINARY
  awk
)
find_program(PASTE_BINARY
  paste
)


# fetch_opencv()
#   Uses FetchContent to download and config OpenCV (default 4.10.0), providing
#     workaround for library's lack of modern CMake FetchContent integration, see:
#     - https://github.com/opencv/opencv/issues/20548
#
#   CHECK_PKG_DEPS (bool, optional): check for supporting system packages
#   GIT_TAG (string, optional): git tag or hash to pass to FetchContent_Declare
#   CONFIG (list, optional): OpenCV (4.10.0 as reference) configuration
#     options, see:
#     - https://docs.opencv.org/4.10.0/db/d05/tutorial_config_reference.html
#
function(fetch_opencv)

  ###
  ### define setup vars
  ###

  set(DEFAULT_GIT_TAG "4.10.0")

  # base or contrib modules, typically added via ocv_add_module(), will define a
  #   set of CMAKE_MODULE_opencv_<module>_* vars, see:
  #   - https://github.com/opencv/opencv/blob/4.10.0/cmake/OpenCVModule.cmake

  # modules that have a opencv/modules/<module>/include directory, see:
  #   - https://github.com/opencv/opencv/tree/4.10.0/modules
  set(BASE_MODULE_LIST
    calib3d
    core
    dnn
    features2d
    flann
    gapi
    highgui
    imgcodecs
    imgproc
    ml
    objdetect
    photo
    stitching
    ts
    video
    videoio
    world
  )

  # contrib modules that have a opencv_contrib/modules/<module>/include directory, see:
  #   - https://github.com/opencv/opencv_contrib/tree/4.10.0/modules
  set(CONTRIB_MODULE_LIST
    alphamat
    aruco
    bgsegm
    bioinspired
    cannops
    ccalib
    cnn_3dobj
    cudaarithm
    cudabgsegm
    cudacodec
    cudafeatures2d
    cudafilters
    cudaimgproc
    cudalegacy
    cudaobjdetect
    cudaoptflow
    cudastereo
    cudawarping
    cudev
    cvv
    datasets
    dnn_objdetect
    dnns_easily_fooled
    dnn_superres
    dpm
    face
    freetype
    fuzzy
    hdf
    hfs
    img_hash
    intensity_transform
    julia
    line_descriptor
    matlab
    mcc
    optflow
    ovis
    phase_unwrapping
    plot
    quality
    rapid
    reg
    rgbd
    saliency
    sfm
    shape
    signal
    stereo
    structured_light
    superres
    surface_matching
    text
    tracking
    videostab
    viz
    wechat_qrcode
    xfeatures2d
    ximgproc
    xobjdetect
    xphoto
  )

  ###
  ### parse args
  ###

  set(options
    CHECK_PKG_DEPS
  )
  set(single_value_args
    GIT_TAG
  )
  set(multi_value_args
    CONFIG
  )
  cmake_parse_arguments("OCV"
    "${options}" "${single_value_args}" "${multi_value_args}"
    ${ARGN}
  )
  if(OCV_UNPARSED_ARGUMENTS)
    message(WARNING
      "fetch_opencv: unparsed arguments: \"${OCV_UNPARSED_ARGUMENTS}\"")
  endif()

  set(_inside_fetch_opencv TRUE)
  # defines RECOGNIZED_OPENCV_CONFIG_VARS, <config var>_TYPE, and <config var>_DOC
  include(SetOpenCVConfigSupportVars)
  unset(_inside_fetch_opencv)
  cmake_parse_arguments("OCV_CONFIG"
    "" "${RECOGNIZED_OPENCV_CONFIG_VARS}" ""
    ${OCV_CONFIG}
  )
  if(OCV_CONFIG_UNPARSED_ARGUMENTS)
    message(WARNING
      "fetch_opencv: unparsed CONFIG arguments: \"${OCV_CONFIG_UNPARSED_ARGUMENTS}\"")
  endif()

  ###
  ### fetch repo and configure using defined CONFIG variables
  ###

  if(OCV_GIT_TAG)
    set(git_tag ${OCV_GIT_TAG})
  else()
    set(git_tag ${DEFAULT_GIT_TAG})
  endif()

  # Caching variables before FetchContent calls takes place of defining in cli
  #   with -D (one cannot pass CMAKE_ARGS to FetchContent_Declare as one would
  #   to ExternalProject_Add,) see:
  #   - https://cmake.org/cmake/help/v3.31/module/FetchContent.html#command:fetchcontent_declare
  #   - https://cmake.org/cmake/help/v3.31/module/ExternalProject.html#configure-step-options
  foreach(config_var ${RECOGNIZED_OPENCV_CONFIG_VARS})
    if(DEFINED OCV_CONFIG_${config_var})
      set(${config_var} "${OCV_CONFIG_${config_var}}" CACHE
        ${${config_var}_TYPE} "${${config_var}_DOC}" FORCE)
    endif()
  endforeach()

  set(building_contrib_modules FALSE)
  foreach(module ${CONTRIB_MODULE_LIST})
    if(OCV_CONFIG_BUILD_opencv_${module} OR
        "${OCV_CONFIG_BUILD_LIST}" MATCHES ",*${module},*")
      set(building_contrib_modules TRUE)
      break()
    endif()
  endforeach()
  if(OCV_CONFIG_OPENCV_EXTRA_MODULES_PATH)
    find_path(valid_extra_modules_path
      ""
      PATHS ${OCV_CONFIG_OPENCV_EXTRA_MODULES_PATH}
      NO_DEFAULT_PATH
      NO_CACHE
    )
  endif()

  if(building_contrib_modules AND NOT valid_extra_modules_path)

    FetchContent_Declare(OpenCVContrib
      GIT_REPOSITORY "https://github.com/opencv/opencv_contrib.git"
      GIT_TAG        "${git_tag}"
    )
    FetchContent_MakeAvailable(OpenCVContrib)

    message(WARNING
      " fetch_opencv: contrib modules selected for build, but \
OPENCV_EXTRA_MODULES_PATH of\n"
      "   '${OCV_CONFIG_OPENCV_EXTRA_MODULES_PATH}'\n"
      " not valid, defaulting to:\n"
      "   ${opencvcontrib_SOURCE_DIR}/modules")
      set(OCV_CONFIG_OPENCV_EXTRA_MODULES_PATH ${opencvcontrib_SOURCE_DIR}/modules)
  endif()

  set(OPENCV_EXTRA_MODULES_PATH
    "${OCV_CONFIG_OPENCV_EXTRA_MODULES_PATH}" CACHE
    ${OPENCV_EXTRA_MODULES_PATH_TYPE} ${OPENCV_EXTRA_MODULES_PATH_DOC} FORCE)

  FetchContent_Declare(OpenCV
    GIT_REPOSITORY "https://github.com/opencv/opencv.git"
    GIT_TAG        "${git_tag}"
    GIT_SHALLOW
  )
  FetchContent_MakeAvailable(OpenCV)

  ###
  ### issue warnings if missing system packages required for selected modules
  ###

  if(OCV_CHECK_PKG_DEPS)
    if(NOT DEBIAN_VERSION_FILE)
      message(WARNING "fetch_opencv: currently only supporting Debian-derived \
distros with apt package manager when detecting dependency packages")
    endif()
    if(NOT APT_BINARY OR NOT APT_CACHE_BINARY OR
        NOT AWK_BINARY OR NOT PASTE_BINARY)
      message(FATAL_ERROR "fetch_opencv: requires apt, apt-cache, awk and \
paste to detect dependency packages")
    endif()

    # TBD consider issuing warning if requested modules are disabled by opencv config

    # OPENCV_MODULES_BUILD should be list of all modules:
    #   - not disabled directly via BUILD_opencv_<module>=OFF
    #   - not omitted from BUILD_LIST, if defined
    #   - not disabled by other opencv config conditions
    #   - that also includes required inter-module dependencies of selected modules
    #   - that does not include optional inter-module dependencies, unless selected
    if(NOT DEFINED OPENCV_MODULES_BUILD)
      message(FATAL_ERROR "fetch_opecv: expected OPENCV_MODULES_BUILD to be
defined by OpenCV configuration")
    endif()
    set(components_to_build ${OPENCV_MODULES_BUILD})
    # apps can only be disabled by setting BUILD_opencv_apps=OFF, not via
    #   BUILD_LIST
    # apps may be selected with app whitelist BUILD_APPS_LIST (undocumented):
    #   - https://github.com/opencv/opencv/blob/4.10.0/apps/CMakeLists.txt#L44
    if(BUILD_opencv_apps)
      list(APPEND components_to_build opencv_apps)
    endif()
    list(SORT components_to_build)
    list(REMOVE_DUPLICATES components_to_build)
    list(TRANSFORM components_to_build REPLACE "^opencv_\([a-z0-9_]+\)$" "\\1")

    foreach(component ${components_to_build})
      if(${component} STREQUAL "apps")
        set(err_msg_infix "")
      else()
        set(err_msg_infix "module ")
      endif()
      if(NOT DEFINED CACHE{${component}_PACKAGE_DEPS})
        execute_process(
          # Debian package naming scheme
          COMMAND apt-cache depends "libopencv-${component}-dev"
          COMMAND awk "/Depends:/ { print $2 }"
          COMMAND paste -sd ";"
          OUTPUT_VARIABLE ${component}_package_deps
          ERROR_QUIET
          #COMMAND_ERROR_IS_FATAL ANY
        )
        # remove trailing newline
        string(STRIP "${${component}_package_deps}" ${component}_package_deps)
        foreach(pkg ${${component}_package_deps})
          # inter-package dependencies handled by OpenCV config, not needed here
          if(${pkg} MATCHES "libopencv-[a-z0-9]+-dev")
            list(REMOVE_ITEM ${component}_package_deps ${pkg})
          endif()
        endforeach()
        set(${component}_PACKAGE_DEPS ${${component}_package_deps} CACHE STRING
          "fetch_opencv: non-module package dependencies of OpenCV \
${err_msg_infix}'${component}'")
      endif()
      list(JOIN ${component}_PACKAGE_DEPS " " ${component}_PACKAGE_DEPS_string)
      execute_process(
        COMMAND apt list --installed ${${component}_PACKAGE_DEPS}
        COMMAND awk -F "/" "/\\// { print $1 }"
        COMMAND paste -sd ";"
        OUTPUT_VARIABLE installed_pkgs
        ERROR_QUIET
        #COMMAND_ERROR_IS_FATAL ANY
      )
      # remove trailing newline
      string(STRIP "${installed_pkgs}" installed_pkgs)
      set(missing_pkgs)  # reused every loop
      foreach(pkg ${${component}_PACKAGE_DEPS})
        if(NOT ${pkg} IN_LIST installed_pkgs)
          list(APPEND missing_pkgs ${pkg})
        endif()
      endforeach()
      if(missing_pkgs)
        list(JOIN missing_pkgs " " missing_pkgs_string)
        # indent cmake warnings and errors to skip autoformatting, see:
        #   - https://stackoverflow.com/a/51035045
        message(WARNING
          " fetch_opencv: OpenCV ${err_msg_infix}'${component}' expects \
non-module system packages:\n"
          "     ${${component}_PACKAGE_DEPS_string}\n"
          " but could not find:\n"
          "     ${missing_pkgs_string}\n")
      endif()
    endforeach()
  endif()

  ###
  ### export FetchContent and find_package-alike variables for consumption
  ###   by linking targets
  ###

  # FetchContent_Populate()-defined variables only set in current scope
  set(opencv_POPULATED ${opencv_POPULATED} PARENT_SCOPE)
  set(opencv_SOURCE_DIR ${opencv_SOURCE_DIR} PARENT_SCOPE)
  set(opencv_BINARY_DIR ${opencv_BINARY_DIR} PARENT_SCOPE)
  if(opencvcontrib_POPULATED)
    set(opencvcontrib_POPULATED ${opencvcontrib_POPULATED} PARENT_SCOPE)
    set(opencvcontrib_SOURCE_DIR ${opencvcontrib_SOURCE_DIR} PARENT_SCOPE)
    set(opencvcontrib_BINARY_DIR ${opencvcontrib_BINARY_DIR} PARENT_SCOPE)
  endif()

  # OPENCV_MODULES_PUBLIC should be OPENCV_MODULES_BUILD, minus any modules not
  #   publicly linkable as targets (notably language bindings)
  if(NOT DEFINED OPENCV_MODULES_PUBLIC)
    message(FATAL_ERROR "fetch_opecv: expected OPENCV_MODULES_PUBLIC to be
defined by OpenCV configuration")
  endif()
  set(project_linkable_modules ${OPENCV_MODULES_PUBLIC})
  list(SORT project_linkable_modules)
  list(REMOVE_DUPLICATES project_linkable_modules)

  # working around OpenCV not supporting FetchContent patterns requires a
  #   variable list of include directories and linked targets, so we define
  #   *_INCLUDE_DIRS and *_LIBRARIES as find_package() would; solution builds
  #   off of:
  #   - https://github.com/opencv/opencv/issues/20548#issuecomment-1325751099
  set(OpenCV_INCLUDE_DIRS
    ${opencv_SOURCE_DIR}/include
    ${OPENCV_CONFIG_FILE_INCLUDE_DIR}
  )
  foreach(module ${project_linkable_modules})
    list(APPEND OpenCV_INCLUDE_DIRS
      "${OPENCV_MODULE_${module}_LOCATION}/include")
    # OpenCV defines library targets on a per-module basis, see OpenCVModule.cmake
    list(APPEND OpenCV_LIBRARIES "${module}")
  endforeach()
  set(OpenCV_INCLUDE_DIRS ${OpenCV_INCLUDE_DIRS} PARENT_SCOPE)
  set(OpenCV_LIBRARIES ${OpenCV_LIBRARIES} PARENT_SCOPE)

endfunction()
