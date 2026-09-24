# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonTargetErrors VERSION 0.1.0 LANGUAGES NONE)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()
if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (CANON_TEST_CASE STREQUAL "missing")
    canon_apply_target(missing)
elseif (CANON_TEST_CASE STREQUAL "interface")
    add_library(sample_interface INTERFACE)
    canon_apply_target(sample_interface)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
