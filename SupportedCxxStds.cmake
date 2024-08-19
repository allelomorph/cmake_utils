# CMAKE_CXX_COMPILE_FEATURES v3.1
# list(FILTER) v3.5
# list(TRANSFORM) v3.12
cmake_minimum_required(VERSION 3.12)

include_guard(DIRECTORY)

# supported_cxx_stds()
#   sets SUPPORTED_CXX_STDS to list of compiler supported C++ standards as
#     2-digit year suffixes, eg "98;11;14"
macro(supported_cxx_stds)
  set(cxx_stds ${CMAKE_CXX_COMPILE_FEATURES})
  list(FILTER cxx_stds
    INCLUDE REGEX "^cxx_std_[0-9][0-9]")
  list(TRANSFORM cxx_stds
    REPLACE "^cxx_std_" "")
  set(SUPPORTED_CXX_STDS ${cxx_stds})
  unset(cxx_stds)
endmacro()
