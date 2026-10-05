# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyResolveNestedProviderFirst LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

canon_resolve_dependency(
    mid
    PACKAGE MidFixture
    VERSION "7.3...<8.0"
    TARGETS MidFixture::Core
)
canon_resolve_dependency(
    leaf
    PACKAGE LeafFixture
    VERSION "7.3...<8.0"
    TARGETS LeafFixture::Support
)
