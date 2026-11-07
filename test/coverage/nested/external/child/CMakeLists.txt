# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(CanonCoverageNestedChild LANGUAGES CXX)

add_library(child STATIC child.cpp external/child_vendor.cpp)
canon_apply_library(child)
add_executable(child_test child_test.cpp)
target_link_libraries(child_test PRIVATE child)
canon_apply_target(child_test)
add_test(NAME child_test COMMAND child_test)
