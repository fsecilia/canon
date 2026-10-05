# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyInstallBuild LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

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

get_target_property(_excluded dependency_fixture_runtime EXCLUDE_FROM_ALL)
if (NOT _excluded)
    message(FATAL_ERROR
        "canon_install_dependency() changed the vendored target's EXCLUDE_FROM_ALL property")
endif()

include(GNUInstallDirs)
file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/install-data.txt"
    CONTENT "${CMAKE_INSTALL_LIBDIR}\n$<TARGET_FILE_NAME:dependency_fixture_runtime>\n"
)
