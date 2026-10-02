# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(ToolPackage VERSION 0.8.6 LANGUAGES CXX)

add_library(tool_api INTERFACE)
_canon_package_fixture_add_headers(tool_api INTERFACE tool_package/sample.hpp)
canon_apply_library(tool_api)

add_executable(sample_tool "${CMAKE_CURRENT_LIST_DIR}/../../../support/empty_main.cpp")
canon_apply_executable(sample_tool)
