# TBD re-evaluate supported versions
cmake_minimum_required(VERSION 3.16)

# no real need for include_guard, as false condition causes fatal error
include_guard(DIRECTORY)

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR
    "In-source builds not allowed on this project. \
    Please provide a path to a separate build directory:\n\
    cmake -S <source dir> -B <build dir>\n"
    "Manual cleanup of configuration stage can be done by deleting:\n\
    ${PROJECT_SOURCE_DIR}/CMakeCache.txt\n\
    ${PROJECT_SOURCE_DIR}/CMakeFiles/\n"
    )
endif()
