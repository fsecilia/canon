# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(LeafFixture LANGUAGES NONE)

add_library(leaf_fixture_core INTERFACE)
add_library(LeafFixture::Core ALIAS leaf_fixture_core)
