# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(mixed_core STATIC sample.cpp)
_canon_package_fixture_add_headers(mixed_core PUBLIC mixed/sample.hpp)
canon_apply_library(mixed_core)
