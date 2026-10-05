# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonGoogleTestVendored LANGUAGES CXX)

if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

add_subdirectory("${CANON_SOURCE_DIR}" canon EXCLUDE_FROM_ALL)

if(TARGET GTest::gmock_main OR TARGET GTest::gtest_main)
    message(FATAL_ERROR "Loading Canon eagerly provided GoogleTest targets")
endif()

canon_require_googletest()

foreach(_required_target IN ITEMS GTest::gmock_main GTest::gtest_main)
    if(NOT TARGET "${_required_target}")
        message(FATAL_ERROR "Canon did not provide '${_required_target}'")
    endif()
endforeach()

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/installed-marker.txt" "Canon GoogleTest vendored fixture\n")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/installed-marker.txt" DESTINATION share/canon-gtest-fixture)
