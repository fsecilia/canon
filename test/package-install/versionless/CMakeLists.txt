# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(VersionlessPackage LANGUAGES CXX)

add_library(versionless_api INTERFACE)
_canon_package_fixture_add_headers(versionless_api INTERFACE versionless/sample.hpp)
canon_apply_library(versionless_api)
