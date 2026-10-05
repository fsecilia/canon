cmake_minimum_required(VERSION 3.31.6)
project(canon_export_macro_collision LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_library(first SHARED first.cpp)
add_library(second SHARED second.cpp)

canon_generate_export_header(first first/export.hpp SHARED_API)
canon_generate_export_header(second second/export.hpp SHARED_API)
