# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryErrors LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../../support/CanonSourceFixture.cmake")

enable_language(CXX)
add_library(first STATIC)
set_target_properties(first PROPERTIES EXPORT_NAME FooBar)
canon_apply_library(first)
add_library(second STATIC)
set_target_properties(
    second
    PROPERTIES
        EXPORT_NAME Other
        CANON_EXPORT_IDENTITY FOO_BAR
)
canon_apply_library(second)
