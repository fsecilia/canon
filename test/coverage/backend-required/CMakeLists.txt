# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageBackendRequiredFixture LANGUAGES CXX)

if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()
if(NOT DEFINED CANON_TEST_COVERAGE_COMPILER OR "${CANON_TEST_COVERAGE_COMPILER}" STREQUAL "")
    message(FATAL_ERROR "CANON_TEST_COVERAGE_COMPILER is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

set(CMAKE_CXX_COMPILER "${CANON_TEST_COVERAGE_COMPILER}")

add_library(covered STATIC covered.cpp)
canon_apply_library(covered)
