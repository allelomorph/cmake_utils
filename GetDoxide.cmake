# newest feature TBD
cmake_minimum_required(VERSION 3.20)

if(doxide_POPULATED)
  return()
endif()

if(NOT COMMAND FetchContent_Declare OR
    NOT COMMAND FetchContent_MakeAvailable)
  include(FetchContent)
endif()

set(patch_path ${CMAKE_CURRENT_BINARY_DIR}/patches/doxide)

# Updating use of CMAKE_SOURCE_DIR to CMAKE_CURRENT_SOURCE_DIR allows it to
#   work both as a standalone build and as a FetchContent dependency
if(NOT EXISTS ${patch_path}/downstream_FetchContent.patch)
  file(WRITE ${patch_path}/downstream_FetchContent.patch [[
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 3d8a966..059d8bb 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -58,15 +58,15 @@ target_link_libraries(doxide
 )
 
 configure_file(
-    ${CMAKE_SOURCE_DIR}/src/config.h.in
-    ${CMAKE_SOURCE_DIR}/src/config.h
+    ${CMAKE_CURRENT_SOURCE_DIR}/src/config.h.in
+    ${CMAKE_CURRENT_SOURCE_DIR}/src/config.h
 )
 
 include(GNUInstallDirs)
 install(TARGETS doxide RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
 
-set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/win ${CMAKE_MODULE_PATH})
-string(REPLACE "/" "\\\\" NATIVE_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
+set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/win ${CMAKE_MODULE_PATH})
+string(REPLACE "/" "\\\\" NATIVE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
 set(CPACK_PACKAGE_NAME "Doxide")
 set(CPACK_PACKAGE_ICON "${NATIVE_SOURCE_DIR}\\\\win\\\\icon.ico")
 set(CPACK_PACKAGE_VENDOR "Lawrence Murray")
]])
endif()

# Updating comment block parsing to ignore @brief (as a token) and @file (by
#   skipping the entire comment block) improves cross-compatibility with Doxygen
if(NOT EXISTS ${patch_path}/ignore_file_and_brief_cmds.patch)
  file(WRITE ${patch_path}/ignore_file_and_brief_cmds.patch [[
diff --git a/src/Doc.cpp b/src/Doc.cpp
index 5cdea02..d8d1511 100644
--- a/src/Doc.cpp
+++ b/src/Doc.cpp
@@ -81,9 +81,11 @@ Doc::Doc(const std::string_view comment, const int init_indent) :
           docs.append("\n:material-location-exit: **Return**\n:   ");
         } else if (command == "sa") {
           docs.append("\n:material-eye-outline: **See**\n:   ");
-        } else if (command == "file" ||
-            command == "internal") {
-          hide = true;
+        } else if (command == "file") {
+            /* ignore entire comment (for Doxygen cross-compatibility) */
+            tokenizer.consume(CLOSE);
+        } else if (command == "internal") {
+            hide = true;
         } else if (command == "e" ||
             command == "em" ||
             command == "a") {
@@ -145,6 +147,8 @@ Doc::Doc(const std::string_view comment, const int init_indent) :
             command == "property") {
           /* ignore, including following name */
           tokenizer.consume(WORD);
+        } else if (command == "brief") {
+          /* ignore token (for Doxygen cross-compatibility) */
         } else if (command == "@") {
           docs.append("@");
         } else if (command == "/") {
]])
endif()

# Doxide v0.9.0 (latest tag at time of writing) uses git submodules rather than
#   FetchContent, perhaps due to not building any of the dependencies other
#   than YAML (when requested.) Cloning is much quicker when using
#   --shallow-submodules so that all repos are at a depth of 1.
#   However, while FetchContent supports --depth 1 (GIT_SHALLOW) and
#   --recurse-submodules (GIT_SUBMODULES_RECURSE,) it does not support
#   --shallow-submodules:
#   - https://gitlab.kitware.com/cmake/cmake/-/issues/16144
#   So we must use a custom DOWNLOAD_COMMAND
set(FETCHCONTENT_QUIET OFF)
set(bash_prefix     "/usr/bin/bash" "-c" )
set(git_repository  https://github.com/lawmurray/doxide.git )
set(git_tag         v0.9.0 )
set(fc_src_dir      ${FETCHCONTENT_BASE_DIR}/doxide-src )
set(clone_options
  "--branch ${git_tag} --depth 1 --recurse-submodules --shallow-submodules" )
set(patch_paths
  ${patch_path}/downstream_FetchContent.patch
  ${patch_path}/ignore_file_and_brief_cmds.patch
)
list(JOIN patch_paths " " patch_paths)

set(BUILD_YAML ON CACHE BOOL "build Doxide libyaml dependency from source")
set(BUILD_TESTING OFF CACHE BOOL "skip building Doxide libyaml dependency tests")

# Each *_COMMAND works best when internally idempotent, always exits with 0,
#   and contains no enescaped semicolons
FetchContent_Declare(doxide
  DOWNLOAD_COMMAND ${bash_prefix}
    "git -C ${fc_src_dir} pull &> /dev/null || \
      git clone ${clone_options} ${git_repository} ${fc_src_dir}"
  PATCH_COMMAND ${bash_prefix}
    "git diff --quiet && git apply ${patch_paths} || true"
  )
FetchContent_MakeAvailable(doxide)

unset(patch_path)
set(FETCHCONTENT_QUIET ON)
unset(bash_prefix)
unset(git_repository)
unset(git_tag)
unset(fc_src_dir)
unset(clone_options)
unset(patch_paths)
