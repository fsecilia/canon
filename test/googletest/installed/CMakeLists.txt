# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonGoogleTestInstalled LANGUAGES NONE)

foreach(_required_variable CANON_EXPECTED_VERSION CANON_EXPECTED_DIR)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

find_package(Canon "${CANON_EXPECTED_VERSION}" CONFIG REQUIRED)

if (TARGET GTest::gmock_main OR TARGET GTest::gtest_main)
    message(FATAL_ERROR "Loading installed Canon eagerly provided GoogleTest targets")
endif()

canon_require_googletest()

foreach(_required_target IN ITEMS GTest::gmock_main GTest::gtest_main)
    if (NOT TARGET "${_required_target}")
        message(FATAL_ERROR "Installed Canon did not recover '${_required_target}'")
    endif()
endforeach()
