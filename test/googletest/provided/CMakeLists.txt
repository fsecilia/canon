# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonGoogleTestProvided LANGUAGES NONE)

if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

add_library(GTest::gmock_main INTERFACE IMPORTED GLOBAL)
add_library(GTest::gtest_main INTERFACE IMPORTED GLOBAL)

add_subdirectory("${CANON_SOURCE_DIR}" canon EXCLUDE_FROM_ALL)
canon_require_googletest()
