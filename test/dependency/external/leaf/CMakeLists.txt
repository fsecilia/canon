# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# An alternate leaf provider. Once mid has resolved leaf, Canon must never fall through to this one.
project(LeafFixtureAlternate LANGUAGES NONE)
add_library(leaf_support INTERFACE)
add_library(LeafFixture::Support ALIAS leaf_support)
