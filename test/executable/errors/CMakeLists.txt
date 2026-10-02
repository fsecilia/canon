# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableErrors LANGUAGES NONE)

if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "missing")
    canon_apply_executable(missing)
elseif ("${CANON_TEST_CASE}" STREQUAL "library")
    add_library(sample INTERFACE)
    canon_apply_executable(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "bundle")
    add_executable(sample IMPORTED)
    set_property(TARGET sample PROPERTY MACOSX_BUNDLE TRUE)
    canon_apply_executable(sample)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
