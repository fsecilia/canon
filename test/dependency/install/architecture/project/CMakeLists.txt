# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(ArchitectureFixture VERSION 0.7.3 LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

add_library(architecture_fixture INTERFACE)
target_sources(
    architecture_fixture
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/architecture_fixture/sample.hpp"
)
canon_apply_library(architecture_fixture)

canon_resolve_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS DependencyFixture::Runtime
)
canon_install_dependency(
    fixture-dependency
    TARGETS DependencyFixture::Runtime
)
