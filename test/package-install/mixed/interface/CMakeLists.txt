# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(mixed_headers INTERFACE)
_canon_package_fixture_add_headers(mixed_headers INTERFACE mixed/header_only.hpp)
canon_apply_library(mixed_headers)
