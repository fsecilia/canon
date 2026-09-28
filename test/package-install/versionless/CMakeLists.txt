# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(VersionlessPackage LANGUAGES CXX)

add_library(versionless_api INTERFACE)
target_sources(
    versionless_api
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/versionless/sample.hpp"
)
canon_apply_library(versionless_api)
