# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonVendoredTidyVersionFixture LANGUAGES CXX)

if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

if(NOT CANON_ENABLE_TIDY)
    message(FATAL_ERROR "vendored tidy version fixture requires CANON_ENABLE_TIDY=ON")
endif()

add_subdirectory("${CANON_SOURCE_DIR}" canon EXCLUDE_FROM_ALL)

add_executable(vendored_tidy_version ../tidy_probe.cpp)
canon_apply_target(vendored_tidy_version)
