# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableErrors LANGUAGES NONE)

foreach(_required_variable CANON_SOURCE_DIR CANON_TEST_CASE)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if ("${CANON_TEST_CASE}" STREQUAL "missing")
    canon_apply_executable(missing)
elseif ("${CANON_TEST_CASE}" STREQUAL "library")
    add_library(sample INTERFACE)
    canon_apply_executable(sample)
elseif ("${CANON_TEST_CASE}" STREQUAL "bundle")
    add_executable(sample IMPORTED)
    set_property(TARGET sample PROPERTY MACOSX_BUNDLE TRUE)
    canon_apply_executable(sample)
else()
    message(FATAL_ERROR "Unknown CANON_TEST_CASE '${CANON_TEST_CASE}'")
endif()
