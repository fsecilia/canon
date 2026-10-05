# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(LeafFixtureAlternate LANGUAGES NONE)

add_library(leaf_fixture_support INTERFACE)
add_library(LeafFixture::Support ALIAS leaf_fixture_support)
