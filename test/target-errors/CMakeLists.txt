# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonTargetErrors LANGUAGES NONE)

if (NOT DEFINED CANON_TEST_CASE OR "${CANON_TEST_CASE}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_CASE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

# Trigger the requested invalid canon_apply_target() call during configure.
if ("${CANON_TEST_CASE}" STREQUAL "missing")
    canon_apply_target(missing)
elseif ("${CANON_TEST_CASE}" STREQUAL "interface")
    add_library(sample_interface INTERFACE)
    canon_apply_target(sample_interface)
elseif ("${CANON_TEST_CASE}" STREQUAL "asan-unsupported")
    set(CANON_ENABLE_ASAN ON)
    set(CMAKE_CXX_COMPILER_ID Clang)
    set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT MSVC)
    add_library(sample_static STATIC)
    canon_apply_target(sample_static)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
