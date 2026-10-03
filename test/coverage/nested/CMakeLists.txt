# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageNestedRootFixture LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (NOT CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "nested coverage fixture requires CANON_ENABLE_COVERAGE=ON")
endif()

include(CTest)

function(_add_root_coverage_targets)
    add_library(root_covered STATIC root_covered.cpp external/root_excluded.cpp)
    canon_apply_library(root_covered)

    add_executable(root_covered_test root_covered_test.cpp)
    target_link_libraries(root_covered_test PRIVATE root_covered)
    canon_apply_target(root_covered_test)
    add_test(NAME root_covered_test COMMAND root_covered_test)
endfunction()

if (CANON_TEST_COVERAGE_CHILD_FIRST)
    add_subdirectory(external/coverage)
    _add_root_coverage_targets()
else()
    _add_root_coverage_targets()
    add_subdirectory(external/coverage)
endif()
