# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyErrors LANGUAGES NONE)

if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "empty")
    canon_apply_dependency("")
elseif ("${CANON_TEST_CASE}" STREQUAL "required")
    canon_apply_dependency(DependencyFixture REQUIRED)
elseif ("${CANON_TEST_CASE}" STREQUAL "quiet")
    canon_apply_dependency(DependencyFixture QUIET)
elseif ("${CANON_TEST_CASE}" STREQUAL "no-package")
    canon_apply_dependency(DependencyFixture CONFIG)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
