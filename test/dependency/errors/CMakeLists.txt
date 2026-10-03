# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyErrors LANGUAGES NONE)

if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "empty")
    canon_propagate_dependency("")
elseif ("${CANON_TEST_CASE}" STREQUAL "required")
    canon_propagate_dependency(DependencyFixture REQUIRED)
elseif ("${CANON_TEST_CASE}" STREQUAL "quiet")
    canon_propagate_dependency(DependencyFixture QUIET)
elseif ("${CANON_TEST_CASE}" STREQUAL "no-package")
    canon_propagate_dependency(DependencyFixture CONFIG)
elseif ("${CANON_TEST_CASE}" STREQUAL "resolve-empty")
    canon_resolve_dependency(
        ""
        PACKAGE DependencyFixture
        VERSION "7.3...<8.0"
        TARGETS DependencyFixture::Core
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "resolve-version")
    canon_resolve_dependency(
        fixture-dependency
        PACKAGE DependencyFixture
        TARGETS DependencyFixture::Core
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "resolve-targets")
    canon_resolve_dependency(
        fixture-dependency
        PACKAGE DependencyFixture
        VERSION "7.3...<8.0"
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "resolve-partial")
    add_library(DependencyFixture::Core INTERFACE IMPORTED)
    canon_resolve_dependency(
        fixture-dependency
        PACKAGE DependencyFixture
        VERSION "7.3...<8.0"
        TARGETS DependencyFixture::Core DependencyFixture::Support
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "resolve-missing")
    canon_resolve_dependency(
        missing-dependency
        PACKAGE CanonMissingDependencyFixture
        VERSION "7.3...<8.0"
        TARGETS CanonMissingDependencyFixture::Core
    )
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
