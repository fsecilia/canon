# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(CanonCoverageNestedFixture LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (NOT CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "nested coverage fixture requires CANON_ENABLE_COVERAGE=ON")
endif()

include(CTest)

add_library(nested_covered STATIC covered.cpp external/excluded.cpp)
canon_apply_library(nested_covered)

add_executable(nested_covered_test covered_test.cpp)
target_link_libraries(nested_covered_test PRIVATE nested_covered)
canon_apply_target(nested_covered_test)
add_test(NAME nested_covered_test COMMAND nested_covered_test)
