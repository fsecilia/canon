# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(MidFixture LANGUAGES NONE)

canon_resolve_dependency(
    leaf
    PACKAGE LeafFixture
    VERSION "7.3...<8.0"
    TARGETS LeafFixture::Core
)

add_library(mid_fixture_core INTERFACE)
add_library(MidFixture::Core ALIAS mid_fixture_core)
