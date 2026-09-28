# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(ToolPackage VERSION 0.8.6 LANGUAGES CXX)

add_library(tool_api INTERFACE)
target_sources(
    tool_api
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/tool_package/sample.hpp"
)
canon_apply_library(tool_api)

add_executable(sample_tool main.cpp)
canon_apply_executable(sample_tool)
