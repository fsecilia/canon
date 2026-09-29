# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCompilerErrors LANGUAGES CXX)

foreach(_required_variable CANON_SOURCE_DIR CANON_TEST_COMPILER_ID CANON_TEST_FRONTEND_VARIANT)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_executable(sample EXCLUDE_FROM_ALL sample.cpp)

set(CMAKE_CXX_COMPILER_ID "${CANON_TEST_COMPILER_ID}")
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "${CANON_TEST_FRONTEND_VARIANT}")
canon_apply_target(sample)
