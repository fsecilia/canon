cmake_minimum_required(VERSION 3.31.6)
project(canon_export_header_collision LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_library(first SHARED first.cpp)
add_library(second SHARED second.cpp)

canon_generate_export_header(first shared/export.hpp FIRST_API)
canon_generate_export_header(second shared/export.hpp SECOND_API)
