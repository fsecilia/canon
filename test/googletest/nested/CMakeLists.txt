# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonGoogleTestNested LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

add_subdirectory("${CANON_SOURCE_DIR}" canon EXCLUDE_FROM_ALL)

if (TARGET GTest::gmock_main OR TARGET GTest::gtest_main)
    message(FATAL_ERROR "Loading Canon eagerly provided GoogleTest targets")
endif()

add_subdirectory(child)

get_target_property(_gmock_main_target GTest::gmock_main ALIASED_TARGET)
get_target_property(_gmock_binary_dir "${_gmock_main_target}" BINARY_DIR)
set(_expected_binary_dir "${CMAKE_BINARY_DIR}/canon/external/googletest/googlemock")
if (NOT "${_gmock_binary_dir}" STREQUAL "${_expected_binary_dir}")
    message(FATAL_ERROR
        "Nested GoogleTest binary directory '${_gmock_binary_dir}' did not match "
        "'${_expected_binary_dir}'")
endif()

canon_require_googletest()

foreach(_required_target IN ITEMS GTest::gmock_main GTest::gtest_main)
    if (NOT TARGET "${_required_target}")
        message(FATAL_ERROR "Nested GoogleTest resolution did not provide '${_required_target}'")
    endif()
endforeach()
