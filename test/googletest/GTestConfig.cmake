# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if(NOT "${GTest_FIND_VERSION_RANGE}" STREQUAL "1.18.0...<2.0.0")
    message(FATAL_ERROR "GTest received version range '${GTest_FIND_VERSION_RANGE}'")
endif()
add_library(GTest::gmock_main INTERFACE IMPORTED)
add_library(GTest::gtest_main INTERFACE IMPORTED)
