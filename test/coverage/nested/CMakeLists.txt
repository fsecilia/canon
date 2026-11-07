# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# A root project with a nested Canon project beneath its external/ directory. Both projects' sources must be
# reported, and each project's unmanaged external/ sources must be excluded, whichever project registers first.
cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageNestedRoot LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")
include(CTest)

if(CANON_TEST_COVERAGE_CHILD_FIRST)
    add_subdirectory(external/child)
endif()

add_library(root STATIC root.cpp external/root_vendor.cpp)
canon_apply_library(root)
add_executable(root_test root_test.cpp)
target_link_libraries(root_test PRIVATE root)
canon_apply_target(root_test)
add_test(NAME root_test COMMAND root_test)

if(NOT CANON_TEST_COVERAGE_CHILD_FIRST)
    add_subdirectory(external/child)
endif()
