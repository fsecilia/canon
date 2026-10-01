# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageEmptyFixture LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if (NOT CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "coverage fixture requires CANON_ENABLE_COVERAGE=ON")
endif()

add_executable(covered_empty external/main.cpp)
canon_apply_target(covered_empty)

if (NOT TARGET coverage-report)
    message(FATAL_ERROR "coverage-report was not created")
endif()
