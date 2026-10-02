# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(HeaderOnlyPackage VERSION 0.7.3 LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

add_library(header_api INTERFACE)
_canon_package_fixture_add_headers(header_api INTERFACE header_only/sample.hpp)
canon_apply_library(header_api)
