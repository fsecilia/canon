# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyResolveOutside LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

canon_resolve_dependency(
    ../foreign
    PACKAGE ForeignFixture
    VERSION "7.3...<8.0"
    TARGETS ForeignFixture::Core
)
