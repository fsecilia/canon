cmake_minimum_required(VERSION 3.31.6)
project(canon_export_header_outside LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_library(sample SHARED sample.cpp)
canon_generate_export_header(sample ../escaped.hpp SAMPLE_API)
