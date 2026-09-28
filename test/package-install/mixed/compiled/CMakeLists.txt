# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(mixed_core STATIC sample.cpp)
target_sources(
    mixed_core
    PUBLIC
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/mixed/sample.hpp"
)
canon_apply_library(mixed_core)
