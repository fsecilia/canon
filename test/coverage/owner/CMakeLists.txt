# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# A Canon project whose source directory is the root project's external/ directory. That directory belongs to a
# managed project, so it must be reported, while the owned project's own external/ remains excluded.
cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageOwnerRoot LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")
include(CTest)

add_library(root STATIC root.cpp)
canon_apply_library(root)
add_subdirectory(external)

add_executable(root_test root_test.cpp)
target_link_libraries(root_test PRIVATE root owned)
canon_apply_target(root_test)
add_test(NAME root_test COMMAND root_test)
