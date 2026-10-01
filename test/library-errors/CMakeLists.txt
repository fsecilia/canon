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
elseif ("${CANON_TEST_CASE}" STREQUAL "object")
    add_library(sample OBJECT IMPORTED)
    canon_apply_library(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "framework")
    add_library(sample SHARED IMPORTED)
    set_target_properties(sample PROPERTIES FRAMEWORK TRUE)
    canon_apply_library(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "export-header-collision")
    enable_language(CXX)
    add_library(first STATIC)
    set_target_properties(first PROPERTIES EXPORT_NAME FooBar)
    canon_apply_library(first)
    add_library(second STATIC)
    set_target_properties(second PROPERTIES EXPORT_NAME FOOBar)
    canon_apply_library(second)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
