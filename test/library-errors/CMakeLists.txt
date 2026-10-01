# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryErrors LANGUAGES NONE)

if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "missing")
    canon_apply_library(missing)
elseif ("${CANON_TEST_CASE}" STREQUAL "executable")
    add_executable(sample IMPORTED)
    canon_apply_library(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "object")
    add_library(sample OBJECT IMPORTED)
    canon_apply_library(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "framework")
    add_library(sample SHARED IMPORTED)
    set_target_properties(sample PROPERTIES FRAMEWORK TRUE)
    canon_apply_library(sample)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
