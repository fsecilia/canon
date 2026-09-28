# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(HeaderOnlyPackage VERSION 0.7.3 LANGUAGES CXX)

add_library(header_api INTERFACE)
target_sources(
    header_api
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/header_only/sample.hpp"
)
canon_apply_library(header_api)
