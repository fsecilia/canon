# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyInstallSubdirectory LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/../install" CACHE PATH "" FORCE)

canon_resolve_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS DependencyFixture::Runtime
)

add_subdirectory(app)

include(GNUInstallDirs)
file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/install-data.txt"
    CONTENT "${CMAKE_INSTALL_LIBDIR}\n$<TARGET_FILE_NAME:dependency_fixture_runtime>\n$<TARGET_FILE_NAME:dependency_fixture_unrelated>\n"
)
