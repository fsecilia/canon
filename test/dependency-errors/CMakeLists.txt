# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyErrors LANGUAGES NONE)

foreach(_required_variable CANON_SOURCE_DIR CANON_TEST_CASE)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "empty")
    canon_apply_dependency("")
elseif ("${CANON_TEST_CASE}" STREQUAL "required")
    canon_apply_dependency(DependencyFixture REQUIRED)
elseif ("${CANON_TEST_CASE}" STREQUAL "quiet")
    canon_apply_dependency(DependencyFixture QUIET)
elseif ("${CANON_TEST_CASE}" STREQUAL "no-package")
    canon_apply_dependency(DependencyFixture CONFIG)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
