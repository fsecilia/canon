# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(mixed_headers INTERFACE)
target_sources(
    mixed_headers
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/mixed/header_only.hpp"
)
canon_apply_library(mixed_headers)
