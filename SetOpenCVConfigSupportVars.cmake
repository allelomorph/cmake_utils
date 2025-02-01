cmake_minimum_required(VERSION 3.10)  # include_guard v3.10

include_guard(DIRECTORY)

if(NOT _inside_fetch_opencv)
  message(FATAL_ERROR "${CMAKE_CURRENT_LIST_FILE} is only to be included as \
part of fetch_opencv() definition")
endif()

macro(_setOCVCfgSpprtVars var_name cache_type cache_docstring)
  list(APPEND RECOGNIZED_OPENCV_CONFIG_VARS ${var_name})
  set(${var_name}_TYPE ${cache_type})
  set(${var_name}_DOC  ${cache_docstring})
endmacro()

# OpenCV configuration variables and descriptions taken from:
#   - https://docs.opencv.org/4.10.0/db/d05/tutorial_config_reference.html
#   - https://github.com/opencv/opencv/blob/4.10.0/doc/tutorials/introduction/config_reference/config_reference.markdown
# Note that CMake option() does not overwrite cached values, but does set a new
#   docstring with every call. So for any config variable here that also has a
#   call to ocv_option()/OCV_OPTION()/option() in OpenCV source, docstrings here
#   will match those in the source to reduce confusion. Original docstrings will
#   start with 'OpenCV: '.



###
### General options
###

## Build with extra modules

_setOCVCfgSpprtVars(OPENCV_EXTRA_MODULES_PATH           STRING
  "OpenCV: semicolon-separated list of directories containing extra modules \
which will be added to the build")
# Module directory must have compatible layout and CMakeLists.txt, brief
#   description can be found in the Coding Style Guide:
#   https://github.com/opencv/opencv/wiki/Coding_Style_Guide#files


## Debug build

# CMAKE_BUILD_TYPE, see:
#   - https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html

_setOCVCfgSpprtVars(BUILD_WITH_DEBUG_INFO               BOOL
  "Include debug info into release binaries ('OFF' means default settings)")
# Enable debug symbols in Release build

_setOCVCfgSpprtVars(ENABLE_GNU_STL_DEBUG                BOOL
  "Enable GNU STL Debug mode (defines _GLIBCXX_DEBUG)")
# GNU libstdc++ (default for GCC) libraries used in Debug mode, see:
#   https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_macros.html

_setOCVCfgSpprtVars(CV_DISABLE_OPTIMIZATION             BOOL
  "Disable explicit optimized code (dispatched code/intrinsics/loop \
unrolling/etc)")
# Disables various code optimizations, see:
#   https://github.com/opencv/opencv/wiki/CPU-optimizations-build-options


## Static build

# BUILD_SHARED_LIBS # use cmake var

_setOCVCfgSpprtVars(ENABLE_PIC                          BOOL
  "Generate position independent code (necessary for shared libraries)")
# Sets the CMAKE_POSITION_INDEPENDENT_CODE option


## Generate pkg-config info

_setOCVCfgSpprtVars(OPENCV_GENERATE_PKGCONFIG           BOOL
  "Generate .pc file for pkg-config build tool (deprecated)")
# Enables .pc file generation along with standard CMake package


## Build tests, samples and applications

_setOCVCfgSpprtVars(BUILD_TESTS                         BOOL
  "Build accuracy & regression tests")

_setOCVCfgSpprtVars(BUILD_PERF_TESTS                    BOOL
  "Build performance tests")

_setOCVCfgSpprtVars(BUILD_EXAMPLES                      BOOL
  "Build all examples")

_setOCVCfgSpprtVars(BUILD_opencv_apps                   BOOL
  "Build utility applications (used for example to train classifiers)")


## Build limited set of modules

if(NOT BASE_MODULE_LIST)
  message(FATAL_ERROR "BASE_MODULE_LIST must be defined in fetch_opencv()")
endif()
foreach(module ${BASE_MODULE_LIST})
  _setOCVCfgSpprtVars(BUILD_opencv_${module}            BOOL
    "OpenCV: toggle build of module ${module}")
endforeach()

if(NOT CONTRIB_MODULE_LIST)
  message(FATAL_ERROR "CONTRIB_MODULE_LIST must be defined in fetch_opencv()")
endif()
foreach(module ${CONTRIB_MODULE_LIST})
  _setOCVCfgSpprtVars(BUILD_opencv_${module}            BOOL
    "OpenCV: toggle build of contrib module ${module}")
endforeach()

_setOCVCfgSpprtVars(BUILD_LIST                          STRING
  "OpenCV: build only specified modules (plus all modules they depend on) (comma \
separated list)")


## Downloaded dependencies

_setOCVCfgSpprtVars(OPENCV_DOWNLOAD_PATH                PATH
  "OpenCV: alternate location configuration script can download additional \
libraries and files to")


## CPU optimization level

_setOCVCfgSpprtVars(CPU_BASELINE                        STRING
  "OpenCV: select instrction set for compilation: AVX2 on x86_64 (default SSE3); \
VFPV3 and NEON on ARM; VSX on PowerPC")

_setOCVCfgSpprtVars(CPU_DISPATCH                        STRING
  "OpenCV: list of enabled instruction sets for functions that have dispatch \
enabled (comma separated list, set to empty to disable)")

_setOCVCfgSpprtVars(CV_ENABLE_INTRINSICS                BOOL
  "Use intrinsic-based optimized code")
# Disable universal intrinsics

# See also CV_DISABLE_OPTIMIZATION under General Options > Debug Build


## Profiling, coverage, sanitize, hardening, size optimization

_setOCVCfgSpprtVars(ENABLE_PROFILING                    BOOL
  "Enable profiling in the GCC compiler (Add flags: -g -pg)")
# Enable profiling compiler and linker options (GCC or Clang)

_setOCVCfgSpprtVars(ENABLE_COVERAGE	                BOOL
  "Enable coverage collection with  GCov")
# Enable code coverage support (GCC or Clang)

_setOCVCfgSpprtVars(OPENCV_ENABLE_MEMORY_SANITIZER      BOOL
  "Better support for memory/address sanitizers")

_setOCVCfgSpprtVars(ENABLE_BUILD_HARDENING              BOOL
  "Enable hardening of the resulting binaries (against security attacks, \
detects memory corruption, etc)")
# Enable compiler options which reduce possibility of code exploitation (GCC,
#   Clang, MSVC)

_setOCVCfgSpprtVars(ENABLE_LTO                          BOOL
  "Enable Link Time Optimization")
# Enable Link Time Optimization (LTO) (GCC, Clang, MSVC)

_setOCVCfgSpprtVars(ENABLE_THIN_LTO	                BOOL
  "Enable Thin LTO")
# Enable thin LTO which incorporates intermediate bitcode to binaries allowing
#   consumers to optimize their applications later (Clang)


## Enable IPP optimization

_setOCVCfgSpprtVars(OPENCV_IPP_GAUSSIAN_BLUR            BOOL
  "Enable IPP optimizations for GaussianBlur (+8Mb in binary size)")

_setOCVCfgSpprtVars(OPENCV_IPP_MEAN	                BOOL
  "Enable IPP optimizations for mean (+200Kb in binary size)")
# IPP optimizations for mean() / meanStdDev() +0.2Mb

_setOCVCfgSpprtVars(OPENCV_IPP_MINMAX                   BOOL
  "Enable IPP optimizations for minMaxLoc/minMaxIdx (+200Kb in binary size)")

_setOCVCfgSpprtVars(OPENCV_IPP_SUM                      BOOL
  "Enable IPP optimizations for sum (+100Kb in binary size)")



###
### Functional features and dependencies
###

## Heterogeneous computation

_setOCVCfgSpprtVars(WITH_CUDA                           BOOL
  "Include NVidia Cuda Runtime support")
# Enable CUDA acceleration, see OpenCVDetectCUDA.cmake for undocumented CUDA_*
#   vars

_setOCVCfgSpprtVars(WITH_OPENCL                         BOOL
  "Include OpenCL Runtime support")
# https://en.wikipedia.org/wiki/OpenCL


## Image reading and writing (imgcodecs module)

_setOCVCfgSpprtVars(WITH_IMGCODEC_HDR                   BOOL
  "Include HDR support")
# https://en.wikipedia.org/wiki/RGBE_image_format

_setOCVCfgSpprtVars(WITH_IMGCODEC_SUNRASTER             BOOL
  "Include SUNRASTER support")
# https://en.wikipedia.org/wiki/Sun_Raster

_setOCVCfgSpprtVars(WITH_IMGCODEC_PXM                   BOOL
  "Include PNM (PBM,PGM,PPM) and PAM formats support")
# https://en.wikipedia.org/wiki/Netpbm#File_formats

_setOCVCfgSpprtVars(WITH_IMGCODEC_PFM                   BOOL
  "Include PFM formats support")
# https://en.wikipedia.org/wiki/Netpbm#File_formats

_setOCVCfgSpprtVars(WITH_PNG                            BOOL
  "Include PNG support")
# https://en.wikipedia.org/wiki/Portable_Network_Graphics

_setOCVCfgSpprtVars(BUILD_PNG                           BOOL
  "Build libpng from source")
# https://en.wikipedia.org/wiki/Portable_Network_Graphics

_setOCVCfgSpprtVars(WITH_JPEG                           BOOL
  "Include JPEG support")
# https://en.wikipedia.org/wiki/JPEG

_setOCVCfgSpprtVars(BUILD_JPEG                          BOOL
  "Build libjpeg from source")
# https://en.wikipedia.org/wiki/JPEG

_setOCVCfgSpprtVars(WITH_TIFF                           BOOL
  "Include TIFF support")
# https://en.wikipedia.org/wiki/TIFF

_setOCVCfgSpprtVars(BUILD_TIFF                          BOOL
  "Build libtiff from source" )
# https://en.wikipedia.org/wiki/TIFF

_setOCVCfgSpprtVars(WITH_WEBP                           BOOL
  "Include WebP support")
# https://en.wikipedia.org/wiki/WebP

_setOCVCfgSpprtVars(BUILD_WEBP                          BOOL
  "Build WebP from source")
# https://en.wikipedia.org/wiki/WebP

_setOCVCfgSpprtVars(WITH_OPENJPEG                       BOOL
  "Include JPEG2K support (OpenJPEG)")
# https://en.wikipedia.org/wiki/OpenJPEG

_setOCVCfgSpprtVars(BUILD_OPENJPEG                      BOOL
  "Build OpenJPEG from source")
# https://en.wikipedia.org/wiki/OpenJPEG

_setOCVCfgSpprtVars(WITH_JASPER                         BOOL
  "Include JPEG2K support (Jasper)")
# https://en.wikipedia.org/wiki/JasPer

_setOCVCfgSpprtVars(BUILD_JASPER                        BOOL
  "Build libjasper from source")
# https://en.wikipedia.org/wiki/JasPer

_setOCVCfgSpprtVars(WITH_OPENEXR                        BOOL
  "Include ILM support via OpenEXR")
# https://en.wikipedia.org/wiki/OpenEXR

_setOCVCfgSpprtVars(BUILD_OPENEXR                       BOOL
  "Build openexr from source")
# https://en.wikipedia.org/wiki/OpenEXR

_setOCVCfgSpprtVars(WITH_GDAL                           BOOL
  "Include GDAL Support")
# Enable GDAL support for higher-level support for reading PNG, JPEG, TIFF, and
#   others
#   https://en.wikipedia.org/wiki/GDAL

_setOCVCfgSpprtVars(GDAL_DIR                            PATH
  "OpenCV: directory to search for GDAL library")

_setOCVCfgSpprtVars(WITH_GDCM                           BOOL
  "Include DICOM support")
# Enables DICOM medical image format support through GDCM library. This library
#   will be searched using cmake package mechanism, make sure it is installed
#   correctly or manually set GDCM_DIR environment or cmake variable.
#   https://en.wikipedia.org/wiki/DICOM
#   https://en.wikipedia.org/wiki/GDCM

_setOCVCfgSpprtVars(GDCM_DIR                            PATH
  "OpenCV: directory to search for DICOM library")


## Video reading and writing (videoio module)

_setOCVCfgSpprtVars(WITH_V4L                            BOOL
  "Include Video 4 Linux support")
# Capture images from camera using Video4Linux API; Linux kernel headers must be
#   installed
#   https://en.wikipedia.org/wiki/Video4Linux

_setOCVCfgSpprtVars(WITH_FFMPEG                         BOOL
  "Include FFMPEG support")
# Enable integration with FFmpeg library for decoding and encoding video files
#   and network streams; when not on Windows, requires the following prereqs:
#   avcodec, avformat, avutil, swscale, avresample (optional)
#   https://en.wikipedia.org/wiki/FFmpeg

_setOCVCfgSpprtVars(WITH_GSTREAMER                      BOOL
  "Include Gstreamer support")
# Enable integration with GStreamer library for decoding and encoding video
#   files, capturing frames from cameras and network streams
#   https://en.wikipedia.org/wiki/GStreamer

_setOCVCfgSpprtVars(WITH_MSMF                           BOOL
  "Build VideoIO with Media Foundation support")
# Enables MSMF backend which uses Windows' built-in Media Foundation framework
#   for capturing frames from camera, decoding and encoding video files
#   https://en.wikipedia.org/wiki/Media_Foundation

_setOCVCfgSpprtVars(WITH_MSMF_DXVA                      BOOL
  "Enable hardware acceleration in Media Foundation backend")

_setOCVCfgSpprtVars(WITH_DSHOW                          BOOL
  "Build VideoIO with DirectShow support")
# Enables Windows' DirectShow framework backend for capturing frames from camera
#   (deprecated in favor of MSMF backend)
#   https://en.wikipedia.org/wiki/DirectShow

_setOCVCfgSpprtVars(WITH_AVFOUNDATION                   BOOL
  "Use AVFoundation for Video I/O (iOS/visionOS/Mac)")
# AVFoundation framework is part of Apple platforms and can be used to capture
#   frames from camera, encode and decode video files
#   https://en.wikipedia.org/wiki/AVFoundation

_setOCVCfgSpprtVars(WITH_1394                           BOOL
  "Include IEEE1394 support")
# IIDC IEEE1394 support using DC1394 library
#   https://en.wikipedia.org/wiki/IEEE_1394#IIDC

_setOCVCfgSpprtVars(WITH_OPENNI                         BOOL
  "Include OpenNI support")
# OpenNI can be used to capture data from depth-sensing cameras (deprecated)
#   https://en.wikipedia.org/wiki/OpenNI

_setOCVCfgSpprtVars(WITH_OPENNI2                        BOOL
  "Include OpenNI2 support")
# OpenNI2 can be used to capture data from depth-sensing cameras
#   https://structure.io/openni

_setOCVCfgSpprtVars(WITH_PVAPI                          BOOL
  "Include Prosilica GigE support")
# PVAPI is legacy SDK for Prosilica GigE cameras (deprecated)
#   https://www.alliedvision.com/en/support/software-downloads.html

_setOCVCfgSpprtVars(WITH_ARAVIS                         BOOL
  "Include Aravis GigE support")
# Aravis library is used for video acquisition using Genicam cameras
#   https://github.com/AravisProject/aravis

_setOCVCfgSpprtVars(WITH_XIMEA                          BOOL
  "Include XIMEA cameras support")
# https://www.ximea.com/

_setOCVCfgSpprtVars(WITH_XINE                           BOOL
  "Include Xine support (GPL)")
# https://en.wikipedia.org/wiki/Xine

_setOCVCfgSpprtVars(WITH_LIBREALSENSE                   BOOL
  "Include Intel librealsense support")
# https://en.wikipedia.org/wiki/Intel_RealSense

_setOCVCfgSpprtVars(WITH_MFX                            BOOL
  "Include Intel Media SDK support")
# MediaSDK library can be used for HW-accelerated decoding and encoding of raw
#   video streams
#   http://mediasdk.intel.com/

_setOCVCfgSpprtVars(WITH_GPHOTO2                        BOOL
  "Include gPhoto2 library support")
# GPhoto library can be used to capure frames from cameras
#   https://en.wikipedia.org/wiki/GPhoto

_setOCVCfgSpprtVars(WITH_ANDROID_MEDIANDK               BOOL
  "Use Android Media NDK for Video I/O (Android)")
# MediaNDK library is available on Android since API level 21
#   https://developer.android.com/ndk/guides/stable_apis#libmediandk

_setOCVCfgSpprtVars(VIDEOIO_ENABLE_PLUGINS              BOOL
  "Allow building and using of videoio plugins")

_setOCVCfgSpprtVars(VIDEOIO_PLUGIN_LIST                 STRING
  "List of videoio backends to be compiled as plugins (ffmpeg, gstreamer, mfx, \
msmf or special value 'all')")
# Comma- or semicolon-separated list of backend names to be compiled as plugins


## Parallel processing

_setOCVCfgSpprtVars(WITH_PTHREADS_PF                    BOOL
  "Use pthreads-based parallel_for")
# Enables concurrency with pthreads when available on Linux, Android and other
#   Unix-like platforms; see modules/core/src/parallel_impl.cpp for more details
#   https://en.wikipedia.org/wiki/POSIX_Threads

_setOCVCfgSpprtVars(WITH_TBB                            BOOL
  "Include Intel TBB support")
# Enables concurrency with Threading Building Blocks, a cross-platform library
#   for parallel programming
#   https://en.wikipedia.org/wiki/Threading_Building_Blocks

_setOCVCfgSpprtVars(BUILD_TBB                           BOOL
  "Download and build TBB from source")
#   https://en.wikipedia.org/wiki/Threading_Building_Blocks

_setOCVCfgSpprtVars(WITH_OPENMP                         BOOL
  "Include OpenMP support")
# Enables concurrency with OpenMP API, when supported by compiler
#   https://en.wikipedia.org/wiki/OpenMP

_setOCVCfgSpprtVars(WITH_HPX                            BOOL
  "Include Ste||ar Group HPX support")
# Enables concurrency with High Performance ParallelX, an experimental backend
#   which is more suitable for multiprocessor environments.
#   https://en.wikipedia.org/wiki/HPX

_setOCVCfgSpprtVars(PARALLEL_ENABLE_PLUGINS             BOOL
  "Allow building parallel plugin support")


## GUI backends (highgui module)

_setOCVCfgSpprtVars(WITH_GTK                            BOOL
  "Include GTK support")
# GTK is a common toolkit in Linux and Unix-likes. By default v3 will be used if
#   found, v2 can be forced with the WITH_GTK_2_X option
#   https://en.wikipedia.org/wiki/GTK

_setOCVCfgSpprtVars(WITH_GTK_2_X                        BOOL
  "Use GTK version 2")

_setOCVCfgSpprtVars(WITH_WIN32UI                        BOOL
  "Build with Win32 UI Backend support")
# WinAPI is a standard GUI API in Windows
#   https://en.wikipedia.org/wiki/Windows_API

_setOCVCfgSpprtVars(WITH_QT                             BOOL
  "Build with Qt Backend support")
# Qt is a cross-platform GUI framework; OpenCV compiled with Qt support enables
#   advanced highgui interface, see Qt New Functions for details
#   https://en.wikipedia.org/wiki/Qt_(software)
#   https://docs.opencv.org/4.10.0/dc/d46/group__highgui__qt.html

_setOCVCfgSpprtVars(WITH_OPENGL                         BOOL
  "Include OpenGL support")
# Enables OpenGL integration for HW-accelerated window drawing when using GTK,
#   WIN32 and Qt backends

_setOCVCfgSpprtVars(HIGHGUI_ENABLE_PLUGINS              BOOL
  "Allow building and using of GUI plugins")

_setOCVCfgSpprtVars(HIGHGUI_PLUGIN_LIST                 STRING
  "List of GUI backends to be compiled as plugins (gtk, gtk2/gtk3, qt, win32 \
or special value 'all')")
# Comma- or semicolon-separated list of backend names to be compiled


## Deep learning neural networks inference backends and options (dnn module)

_setOCVCfgSpprtVars(WITH_PROTOBUF                       BOOL
  "Enable libprotobuf")
# Enables protobuf library search. OpenCV can either build own copy of the
#   library or use external one. This dependency is required by the dnn module,
#   if it can't be found module will be disabled.

_setOCVCfgSpprtVars(BUILD_PROTOBUF                      BOOL
  "Force to build libprotobuf runtime from sources")
# Build own copy of protobuf. Must be disabled if you want to use external
#   library.

_setOCVCfgSpprtVars(PROTOBUF_UPDATE_FILES               BOOL
  "Force rebuilding .proto files (protoc should be available)")
# Re-generate all .proto files. protoc compiler compatible with used version
#   of protobuf must be installed.

_setOCVCfgSpprtVars(OPENCV_DNN_OPENCL                   BOOL
  "Build with OpenCL support")
# Enable built-in OpenCL inference backend.

_setOCVCfgSpprtVars(WITH_INF_ENGINE                     BOOL
  "OpenCV: Deprecated since OpenVINO 2022.1 Enables Intel Inference Engine \
(IE) backend. Allows to execute networks in IE format (.xml + .bin). Inference \
Engine must be installed either as part of OpenVINO toolkit, either as a \
standalone library built from sources.")
# https://github.com/openvinotoolkit/openvino
# https://en.wikipedia.org/wiki/OpenVINO

_setOCVCfgSpprtVars(INF_ENGINE_RELEASE                  STRING
  "OpenCV: Deprecated since OpenVINO 2022.1 Defines version of Inference Engine \
library which is tied to OpenVINO toolkit version. Must be a 10-digit string, \
e.g. 2020040000 for OpenVINO 2020.4.")

_setOCVCfgSpprtVars(WITH_NGRAPH                          BOOL
  "OpenCV: Deprecated since OpenVINO 2022.1 Enables Intel NGraph library \
support. This library is part of Inference Engine backend which allows executing \
arbitrary networks read from files in multiple formats supported by OpenCV: \
Caffe, TensorFlow, PyTorch, Darknet, etc.. NGraph library must be installed, \
it is included into Inference Engine.")

_setOCVCfgSpprtVars(WITH_OPENVINO                        BOOL
  "Include Intel OpenVINO toolkit support")
# Enable Intel OpenVINO Toolkit support. Should be used for OpenVINO>=2022.1
#   instead of WITH_INF_ENGINE and WITH_NGRAPH.

_setOCVCfgSpprtVars(OPENCV_DNN_CUDA                      BOOL
  "Build with CUDA support")
# Enable CUDA backend. CUDA, CUBLAS and CUDNN must be installed.
#   https://en.wikipedia.org/wiki/CUDA
#   https://developer.nvidia.com/cudnn

_setOCVCfgSpprtVars(WITH_HALIDE                          BOOL
  "Include Halide support")
# Use experimental Halide backend which can generate optimized code for
#   dnn-layers at runtime. Halide must be installed.
#   https://en.wikipedia.org/wiki/Halide_(programming_language)

_setOCVCfgSpprtVars(WITH_VULKAN                          BOOL
  "Include Vulkan support")
# Enable experimental Vulkan backend. Does not require additional dependencies,
#   but can use external Vulkan headers (VULKAN_INCLUDE_DIRS).
#   https://en.wikipedia.org/wiki/Vulkan_(API)



#
# Installation layout
#

## Installation root

# CMAKE_INSTALL_PREFIX, see:
#   - https://cmake.org/cmake/help/latest/variable/CMAKE_INSTALL_PREFIX.html


## Components and locations

_setOCVCfgSpprtVars(INSTALL_C_EXAMPLES                   BOOL
  "Install C examples")
# Install C++ sample sources from the samples/cpp directory

_setOCVCfgSpprtVars(INSTALL_PYTHON_EXAMPLES              BOOL
  "Install Python examples")
# Install Python sample sources from the samples/python directory

_setOCVCfgSpprtVars(INSTALL_ANDROID_EXAMPLES             BOOL
  "Install Android examples")
# Install Android sample sources from the samples/android directory

_setOCVCfgSpprtVars(INSTALL_BIN_EXAMPLES                 BOOL
  "Install prebuilt examples")
# Install prebuilt sample applications (BUILD_EXAMPLES must be enabled)

_setOCVCfgSpprtVars(INSTALL_TESTS                        BOOL
  "Install accuracy and performance test binaries and test data")
# Install tests (BUILD_TESTS must be enabled)

_setOCVCfgSpprtVars(OPENCV_INSTALL_APPS_LIST             STRING
  "OpenCV: Comma- or semicolon-separated list of prebuilt applications to \
install from opencv/apps")
# see also (undocumented) BUILD_APPS_LIST:
#   https://github.com/opencv/opencv/blob/4.10.0/apps/CMakeLists.txt#L44

_setOCVCfgSpprtVars(OPENCV_BIN_INSTALL_PATH              PATH
  "OpenCV: installation directory for applications, dynamic libraries (win)")

_setOCVCfgSpprtVars(OPENCV_TEST_INSTALL_PATH             PATH
  "OpenCV: installation directory for test applications")

_setOCVCfgSpprtVars(OPENCV_SAMPLES_BIN_INSTALL_PATH      PATH
  "OpenCV: installation directory for sample applications")

_setOCVCfgSpprtVars(OPENCV_LIB_INSTALL_PATH              PATH
  "OpenCV: installation directory for dynamic libraries, import libraries (win)")

_setOCVCfgSpprtVars(OPENCV_LIB_ARCHIVE_INSTALL_PATH      PATH
  "OpenCV: installation directory for static libraries")

_setOCVCfgSpprtVars(OPENCV_3P_LIB_INSTALL_PATH           PATH
  "OpenCV: installation directory for 3rd-party libraries")

_setOCVCfgSpprtVars(OPENCV_CONFIG_INSTALL_PATH           PATH
  "OpenCV: installation directory for cmake config package")

_setOCVCfgSpprtVars(OPENCV_INCLUDE_INSTALL_PATH          PATH
  "OpenCV: installation directory for header files")

_setOCVCfgSpprtVars(OPENCV_OTHER_INSTALL_PATH            PATH
  "OpenCV: installation directory for extra data files")

_setOCVCfgSpprtVars(OPENCV_SAMPLES_SRC_INSTALL_PATH      PATH
  "OpenCV: installation directory for sample sources")

_setOCVCfgSpprtVars(OPENCV_LICENSES_INSTALL_PATH         PATH
  "OpenCV: installation directory for licenses for included 3rd-party \
components")

_setOCVCfgSpprtVars(OPENCV_TEST_DATA_INSTALL_PATH        PATH
  "OpenCV: installation directory for test data")

_setOCVCfgSpprtVars(OPENCV_DOC_INSTALL_PATH              PATH
  "OpenCV: installation directory for documentation")

_setOCVCfgSpprtVars(OPENCV_JAR_INSTALL_PATH              PATH
  "OpenCV: installation directory for JAR file with Java bindings")

_setOCVCfgSpprtVars(OPENCV_JNI_INSTALL_PATH              PATH
  "OpenCV: installation directory for JNI part of Java bindings")

_setOCVCfgSpprtVars(OPENCV_JNI_BIN_INSTALL_PATH          PATH
  "OpenCV: installation directory for Dynamic libraries from the JNI part of \
Java bindings")

_setOCVCfgSpprtVars(INSTALL_CREATE_DISTRIB               BOOL
  "OpenCV: tune multiple things to produce Windows and Android distributions.")

_setOCVCfgSpprtVars(INSTALL_TO_MANGLED_PATHS             BOOL
  "OpenCV: adds one level to several installation locations to allow \
side-by-side installations, eg. headers will be installed to \
/usr/include/opencv-4.4.0 instead of /usr/include/opencv4")



###
### Miscellaneous features
###

_setOCVCfgSpprtVars(OPENCV_ENABLE_NONFREE                BOOL
  "Enable non-free algorithms")
# Some algorithms included in the library are known to be protected by patents
#   and are disabled by default

_setOCVCfgSpprtVars(OPENCV_FORCE_3RDPARTY_BUILD          BOOL
  "Force using 3rdparty code from source")
# Enable all BUILD_ options at once

_setOCVCfgSpprtVars(OPENCV_IPP_ENABLE_ALL                BOOL
  "Enable all OPENCV_IPP_ options at once")

_setOCVCfgSpprtVars(ENABLE_CCACHE                        BOOL
  "Use ccache")
# Enable ccache auto-detection. This tool wraps compiler calls and caches
#   results, can significantly improve re-compilation time.
#   https://en.wikipedia.org/wiki/Ccache

_setOCVCfgSpprtVars(ENABLE_PRECOMPILED_HEADERS           BOOL
  "Use precompiled headers")
# Enable precompiled headers support. Improves build time.

_setOCVCfgSpprtVars(BUILD_DOCS                           BOOL
  "Create build rules for OpenCV Documentation")
# Enable documentation build (doxygen, doxygen_cpp, doxygen_python,
#   doxygen_javadoc targets). Doxygen must be installed for C++ documentation
#   build. Python and BeautifulSoup4 must be installed for Python documentation
#   build. Javadoc and Ant must be installed for Java documentation build (part
#   of Java SDK).
#   http://www.doxygen.org/index.html
#   https://en.wikipedia.org/wiki/Beautiful_Soup_(HTML_parser)

_setOCVCfgSpprtVars(ENABLE_PYLINT                        BOOL
  "Add target with Pylint checks")
# Enable python scripts check with Pylint (check_pylint target). Pylint must be
#   installed.
#   https://en.wikipedia.org/wiki/Pylint

_setOCVCfgSpprtVars(ENABLE_FLAKE8                        BOOL
  "Add target with Python flake8 checker")
# Enable python scripts check with Flake8 (check_flake8 target). Flake8 must be
#   installed.
#   https://flake8.pycqa.org/

_setOCVCfgSpprtVars(BUILD_JAVA                           BOOL
  "Enable Java support")
# Enable Java wrappers build. Java SDK and Ant must be installed.

_setOCVCfgSpprtVars(BUILD_FAT_JAVA_LIB                   BOOL
  "Create Java wrapper exporting all functions of OpenCV library (requires \
static build of OpenCV modules)")
# Build single opencv_java dynamic library containing all library functionality
#   bundled with Java bindings. (for static Android builds)

_setOCVCfgSpprtVars(BUILD_opencv_python2                 BOOL
  "OpenCV: Build python2 bindings (deprecated). Python with development files \
and numpy must be installed.")

_setOCVCfgSpprtVars(BUILD_opencv_python3                 BOOL
  "OpenCV: Build python3 bindings. Python with development files and numpy \
must be installed.")

_setOCVCfgSpprtVars(CAROTENE_NEON_ARCH                   STRING
  "Use NVidia carotene acceleration library for ARM platform")
# Switch NEON Arch for Carotene. If it sets nothing, it will be auto-detected.
#   If it sets 8, ARMv8(and later) is used. Otherwise, ARMv7 is used.


## Automated builds

_setOCVCfgSpprtVars(ENABLE_NOISY_WARNINGS                BOOL
  "Show all warnings even if they are too noisy")
# Enables several compiler warnings considered noisy, i.e. having less
#   importance than others. These warnings are usually ignored but in some cases
#   can be worth being checked for.

_setOCVCfgSpprtVars(OPENCV_WARNINGS_ARE_ERRORS           BOOL
  "Treat warnings as errors")
# Treat compiler warnings as errors. Build will be halted.

_setOCVCfgSpprtVars(ENABLE_CONFIG_VERIFICATION           BOOL
  "Fail build if actual configuration doesn't match requested (WITH_XXX != \
HAVE_XXX)")
# For each enabled dependency (WITH_ option) verify that it has been found and
#   enabled (HAVE_ variable). By default feature will be silently turned off if
#   dependency was not found, but with this option enabled cmake configuration
#   will fail. Convenient for packaging systems which require stable library
#   configuration not depending on environment fluctuations.

_setOCVCfgSpprtVars(OPENCV_CMAKE_HOOKS_DIR               PATH
  "OpenCV: OpenCV allows to customize configuration process by adding custom \
hook scripts at each stage and substage. cmake scripts with predefined names \
located in the directory set by this variable will be included before and after \
various configuration stages.")
# Examples of file names: CMAKE_INIT.cmake, PRE_CMAKE_BOOTSTRAP.cmake,
#   POST_CMAKE_BOOTSTRAP.cmake, etc.. Other names are not documented and can be
#   found in the project cmake files by searching for the ocv_cmake_hook macro
#   calls.

_setOCVCfgSpprtVars(OPENCV_DUMP_HOOKS_FLOW               BOOL
  "Dump called OpenCV hooks")
# Enables a debug message print on each cmake hook script call.


## Contrib Modules

_setOCVCfgSpprtVars(WITH_CLP     BOOL
  "Include Clp support (EPL)")
# Will add coinor linear programming library build support which is required in
#   videostab module. Make sure to install the development libraries of
#   coinor-clp, and set OPENCV_EXTRA_MODULES_PATH



###
### Undocumented options
###

# As stated above, docstrings set here will be overwritten by the ones passed
#   to option/ocv_option/OCV_OPTION() in OpenCV source - for any boolean
#   settings below, docstring is as appears in source

## listed at end of 4.10.0 tutorial_config_reference.html

# CMAKE_TOOLCHAIN_FILE, see:
#   - https://cmake.org/cmake/help/latest/variable/CMAKE_TOOLCHAIN_FILE.html

# opencv/cmake/android/OpenCVDetectAndroidSDK.cmake:
_setOCVCfgSpprtVars(ANDROID_HOME                         STRING
  "OpenCV: (undocumented, see OpenCVDetectAndroidSDK.cmake)")

_setOCVCfgSpprtVars(ANDROID_NDK                          STRING
  "OpenCV: (undocumented, see OpenCVDetectAndroidSDK.cmake)")

_setOCVCfgSpprtVars(ANDROID_SDK                          STRING
  "OpenCV: (undocumented, see OpenCVDetectAndroidSDK.cmake)")

_setOCVCfgSpprtVars(ANDROID_SDK_ROOT                     STRING
  "OpenCV: (undocumented, see OpenCVDetectAndroidSDK.cmake)")

# opencv/CMakeLists.txt:
_setOCVCfgSpprtVars(BUILD_ANDROID_EXAMPLES               BOOL
  "Build examples for Android platform")

_setOCVCfgSpprtVars(BUILD_ANDROID_PROJECTS               BOOL
  "Build Android projects providing .apk files")

_setOCVCfgSpprtVars(BUILD_IPP_IW                         BOOL
  "Build IPP IW from source")

_setOCVCfgSpprtVars(BUILD_ITT                            BOOL
  "Build Intel ITT from source")

_setOCVCfgSpprtVars(BUILD_ZLIB                           BOOL
  "Build zlib from source")

_setOCVCfgSpprtVars(WITH_CAROTENE                        BOOL
  "Use NVidia carotene acceleration library for ARM platform")

_setOCVCfgSpprtVars(WITH_CPUFEATURES                     BOOL
  "Use cpufeatures Android library")

_setOCVCfgSpprtVars(WITH_DIRECTX                         BOOL
  "Include DirectX support")

_setOCVCfgSpprtVars(WITH_EIGEN                           BOOL
  "Include Eigen2/Eigen3 support")

_setOCVCfgSpprtVars(WITH_IPP                             BOOL
  "Include Intel IPP support")

_setOCVCfgSpprtVars(WITH_KLEIDICV                        BOOL
  "Use KleidiCV library for ARM platforms")

_setOCVCfgSpprtVars(WITH_LAPACK                          BOOL
  "Include Lapack library support")

_setOCVCfgSpprtVars(WITH_OPENVX                          BOOL
  "Include OpenVX support")

_setOCVCfgSpprtVars(WITH_QUIRC                           BOOL
  "Include library QR-code decoding")

_setOCVCfgSpprtVars(WITH_VA                              BOOL
  "Include VA support")


## discovered during fetch_opencv script development

_setOCVCfgSpprtVars(BUILD_APPS_LIST                      STRING
  "OpenCV: build only specified apps (comma separated whitelist like \
BUILD_LIST, see: \
https://github.com/opencv/opencv/blob/4.10.0/apps/CMakeLists.txt#L44)")


## calls to OCV_OPTION in v4.10.0 for options not mentioned above

#opencv/CMakeLists.txt
_setOCVCfgSpprtVars(ANDROID_EXAMPLES_WITH_LIBS           BOOL
  "Build binaries of Android examples with native libraries")

_setOCVCfgSpprtVars(BUILD_ANDROID_SERVICE                BOOL
  "Build OpenCV Manager for Google Play")

_setOCVCfgSpprtVars(BUILD_CUDA_STUBS                     BOOL
  "Build CUDA modules stubs when no CUDA SDK")

_setOCVCfgSpprtVars(BUILD_KOTLIN_EXTENSIONS              BOOL
  "Build Kotlin extensions (Android)")

_setOCVCfgSpprtVars(BUILD_OBJC                           BOOL
  "Enable Objective-C support")

_setOCVCfgSpprtVars(BUILD_PACKAGE                        BOOL
  "Enables make package_source command")

_setOCVCfgSpprtVars(BUILD_WITH_DYNAMIC_IPP               BOOL
  "Enables dynamic linking of IPP (only for standalone IPP)")

_setOCVCfgSpprtVars(BUILD_WITH_STATIC_CRT                BOOL
  "Enables use of statically linked CRT for statically linked OpenCV")

_setOCVCfgSpprtVars(CV_TRACE                             BOOL
  "Enable OpenCV code trace")

_setOCVCfgSpprtVars(ENABLE_CUDA_FIRST_CLASS_LANGUAGE     BOOL
  "Enable CUDA as a first class language, if enabled dependant projects will \
need to use CMake >= 3.18")

_setOCVCfgSpprtVars(ENABLE_DELAYLOAD                     BOOL
  "Enable delayed loading of OpenCV DLLs")

_setOCVCfgSpprtVars(ENABLE_FAST_MATH                     BOOL
  "Enable compiler options for fast math optimizations on FP computations (not \
recommended)")

_setOCVCfgSpprtVars(ENABLE_IMPL_COLLECTION               BOOL
  "Collect implementation data on function call")

_setOCVCfgSpprtVars(ENABLE_INSTRUMENTATION               BOOL
  "Instrument functions to collect calls trace and performance")

_setOCVCfgSpprtVars(ENABLE_NEON                          BOOL
  "Enable NEON instructions")

_setOCVCfgSpprtVars(ENABLE_OMIT_FRAME_POINTER            BOOL
  "Enable -fomit-frame-pointer for GCC")

_setOCVCfgSpprtVars(ENABLE_POWERPC                       BOOL
  "Enable PowerPC for GCC")

_setOCVCfgSpprtVars(ENABLE_SOLUTION_FOLDERS              BOOL
  "Solution folder in Visual Studio or in other IDEs")

_setOCVCfgSpprtVars(ENABLE_VFPV3                         BOOL
  "Enable VFPv3-D32 instructions")

_setOCVCfgSpprtVars(GENERATE_ABI_DESCRIPTOR              BOOL
  "Generate XML file for abi_compliance_checker tool")

_setOCVCfgSpprtVars(OBSENSOR_USE_ORBBEC_SDK              BOOL
  "Use Orbbec SDK as backend to support more camera models and platforms \
(force to ON on MacOS)")

_setOCVCfgSpprtVars(OPENCV_DISABLE_FILESYSTEM_SUPPORT    BOOL
  "Disable filesystem support")

_setOCVCfgSpprtVars(OPENCV_DISABLE_THREAD_SUPPORT        BOOL
  "Build the library without multi-threaded code.")

_setOCVCfgSpprtVars(OPENCV_ENABLE_MEMALIGN               BOOL
  "Enable posix_memalign or memalign usage")

_setOCVCfgSpprtVars(OPENCV_GENERATE_SETUPVARS            BOOL
  "Generate setup_vars* scripts")

_setOCVCfgSpprtVars(OPENCV_SEMIHOSTING                   BOOL
  "Build the library for semihosting target (Arm). See \
https://developer.arm.com/documentation/100863/latest.")

_setOCVCfgSpprtVars(WITH_ANDROID_NATIVE_CAMERA           BOOL
  "Use Android NDK for Camera I/O (Android)")

_setOCVCfgSpprtVars(WITH_AVIF                            BOOL
  "Enable AVIF support")

_setOCVCfgSpprtVars(WITH_CANN                            BOOL
  "Include CANN support")

_setOCVCfgSpprtVars(WITH_CAP_IOS                         BOOL
  "Enable iOS video capture")

_setOCVCfgSpprtVars(WITH_CUBLAS                          BOOL
  "Include NVidia Cuda Basic Linear Algebra Subprograms (BLAS) library support")

_setOCVCfgSpprtVars(WITH_CUDNN                           BOOL
  "Include NVIDIA CUDA Deep Neural Network (cuDNN) library support")

_setOCVCfgSpprtVars(WITH_CUFFT                           BOOL
  "Include NVidia Cuda Fast Fourier Transform (FFT) library support")

_setOCVCfgSpprtVars(WITH_DIRECTML                        BOOL
  "Include DirectML support")

_setOCVCfgSpprtVars(WITH_FLATBUFFERS                     BOOL
  "Include Flatbuffers support (required by DNN/TFLite importer)")

_setOCVCfgSpprtVars(WITH_ITT                             BOOL
  "Include Intel ITT support")

_setOCVCfgSpprtVars(WITH_NDSRVP                          BOOL
  "Use Andes RVP extension")

_setOCVCfgSpprtVars(WITH_NVCUVENC                        BOOL
  "Include NVidia Video Encoding library support")

_setOCVCfgSpprtVars(WITH_NVCUVID                         BOOL
  "Include NVidia Video Decoding library support")

_setOCVCfgSpprtVars(WITH_OBSENSOR                        BOOL
  "Include obsensor support (Orbbec 3D Cameras)")

_setOCVCfgSpprtVars(WITH_ONNX                            BOOL
  "Include Microsoft ONNX Runtime support")

_setOCVCfgSpprtVars(WITH_OPENCLAMDBLAS                   BOOL
  "Include AMD OpenCL BLAS library support")

_setOCVCfgSpprtVars(WITH_OPENCLAMDFFT                    BOOL
  "Include AMD OpenCL FFT library support")

_setOCVCfgSpprtVars(WITH_OPENCL_D3D11_NV                 BOOL
  "Include NVIDIA OpenCL D3D11 support")

_setOCVCfgSpprtVars(WITH_OPENCL_SVM                      BOOL
  "Include OpenCL Shared Virtual Memory support")

_setOCVCfgSpprtVars(WITH_SPNG                            BOOL
  "Include SPNG support")

_setOCVCfgSpprtVars(WITH_TIMVX                           BOOL
  "Include Tim-VX support")

_setOCVCfgSpprtVars(WITH_UEYE                            BOOL
  "Include UEYE camera support")

_setOCVCfgSpprtVars(WITH_VA_INTEL                        BOOL
  "Include Intel VA-API/OpenCL support")

_setOCVCfgSpprtVars(WITH_VTK                             BOOL
  "Include VTK library support (and build opencv_viz module eiher)")

_setOCVCfgSpprtVars(WITH_WAYLAND                         BOOL
  "Include Wayland support")

_setOCVCfgSpprtVars(WITH_WEBNN                           BOOL
  "Include WebNN support")

_setOCVCfgSpprtVars(WITH_ZLIB_NG                         BOOL
  "Use zlib-ng instead of zlib")

#opencv/cmake/OpenCVDetectCUDA.cmake
#opencv/cmake/OpenCVDetectCUDALanguage.cmake
_setOCVCfgSpprtVars(CUDA_FAST_MATH                       BOOL
  "Enable --use_fast_math for CUDA compiler ")

_setOCVCfgSpprtVars(CUDA_ENABLE_DELAYLOAD                BOOL
  "Enable delayed loading of CUDA DLLs")

#opencv/cmake/OpenCVFindLAPACK.cmake
_setOCVCfgSpprtVars(OPENCV_OSX_USE_ACCELERATE_NEW_LAPACK BOOL
  "Use new BLAS/LAPACK interfaces from Accelerate framework on Apple platform")

#opencv/cmake/OpenCVDetectPython.cmake
_setOCVCfgSpprtVars(PYTHON3_LIMITED_API                   BOOL
  "Build with Python Limited API (not available with numpy >=1.15 <1.17)")

#opencv/cmake/OpenCVDetectCUDAUtils.cmake
_setOCVCfgSpprtVars(CUDA_ENABLE_DEPRECATED_GENERATION    BOOL
  "Enable deprecated generations in the list")

#opencv/cmake/OpenCVFindMKL.cmake
_setOCVCfgSpprtVars(MKL_USE_SINGLE_DYNAMIC_LIBRARY       BOOL
  "Use MKL Single Dynamic Library thorugh mkl_rt.lib / libmkl_rt.so")

_setOCVCfgSpprtVars(MKL_WITH_TBB                         BOOL
  "Use MKL with TBB multithreading")

_setOCVCfgSpprtVars(MKL_WITH_OPENMP                      BOOL
  "Use MKL with OpenMP multithreading")

#opencv/cmake/OpenCVUtils.cmake
_setOCVCfgSpprtVars(BUILD_USE_SYMLINKS                   BOOL
  "Use symlinks instead of files copying during build (and !!INSTALL!!)")

#opencv/3rdparty/libjpeg-turbo/CMakeLists.txt
_setOCVCfgSpprtVars(ENABLE_LIBJPEG_TURBO_SIMD            BOOL
  "Include SIMD extensions for libjpeg-turbo, if available for this platform")

#opencv/3rdparty/libpng/CMakeLists.txt
_setOCVCfgSpprtVars(PNG_HARDWARE_OPTIMIZATIONS           BOOL
  "Enable Hardware Optimizations, if available for this platform")

#opencv/modules/gapi/CMakeLists.txt
_setOCVCfgSpprtVars(OPENCV_GAPI_WITH_OPENVINO            BOOL
  "G-API: Enable OpenVINO Toolkit support")

_setOCVCfgSpprtVars(OPENCV_GAPI_GSTREAMER                BOOL
  "Build G-API with GStreamer support")

#opencv/modules/gapi/cmake/init.cmake
_setOCVCfgSpprtVars(WITH_ADE                             BOOL
  "Enable ADE framework (required for Graph API module)")

_setOCVCfgSpprtVars(WITH_FREETYPE                        BOOL
  "Enable FreeType framework")

_setOCVCfgSpprtVars(WITH_PLAIDML                         BOOL
  "Include PlaidML2 support")

_setOCVCfgSpprtVars(WITH_OAK                             BOOL
  "Include OpenCV AI Kit support")

#opencv/modules/js/CMakeLists.txt
_setOCVCfgSpprtVars(BUILD_WASM_INTRIN_TESTS              BOOL
  "Build WASM intrin tests")

#opencv/modules/dnn/CMakeLists.txt
_setOCVCfgSpprtVars(OPENCV_DNN_TFLITE                    BOOL
  "Build with TFLite support")

_setOCVCfgSpprtVars(OPENCV_DNN_OPENVINO                  BOOL
  "Build with OpenVINO support (2021.4+)")

_setOCVCfgSpprtVars(OPENCV_DNN_PERF_CAFFE                BOOL
  "Add performance tests of Caffe framework")

_setOCVCfgSpprtVars(OPENCV_DNN_PERF_CLCAFFE              BOOL
  "Add performance tests of clCaffe framework")

_setOCVCfgSpprtVars(OPENCV_TEST_DNN_OPENVINO             BOOL
  "Build test with OpenVINO code")

_setOCVCfgSpprtVars(OPENCV_TEST_DNN_CANN                 BOOL
  "Build test with CANN")

_setOCVCfgSpprtVars(OPENCV_TEST_DNN_TIMVX                BOOL
  "Build test with TIM-VX")

_setOCVCfgSpprtVars(OPENCV_TEST_DNN_TFLITE               BOOL
  "Build test with TFLite")

#opencv/modules/videoio/cmake/detect_ffmpeg.cmake
_setOCVCfgSpprtVars(OPENCV_FFMPEG_ENABLE_LIBAVDEVICE     BOOL
  "Include FFMPEG/libavdevice library support.")


## otherwise implied from OpenCV 4.10.0 source
_setOCVCfgSpprtVars(BUILD_opencv_java                    BOOL
  "OpenCV: Build Java bindings")

_setOCVCfgSpprtVars(BUILD_opencv_js                      BOOL
  "OpenCV: Build JavaScript bindings")
