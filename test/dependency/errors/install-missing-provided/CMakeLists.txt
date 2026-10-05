# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyInstallMissingProvided LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

add_library(DependencyFixture::Runtime INTERFACE IMPORTED GLOBAL)

canon_resolve_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS DependencyFixture::Runtime
)

canon_install_dependency(fixture-dependency TARGETS DependencyFixture::Missing)
