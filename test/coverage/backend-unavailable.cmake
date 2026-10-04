# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_SOURCE_DIR)

canon_test_require_variables(
    CANON_TEST_BINARY_DIR
    CANON_CXX_COMPILER_ID
    CANON_CXX_COMPILER_FRONTEND_VARIANT
    CANON_CXX_COMPILER_VERSION
)

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

set(CMAKE_CXX_COMPILER "${CANON_TEST_BINARY_DIR}/missing-cxx-compiler")
set(CMAKE_CXX_COMPILER_ID "${CANON_CXX_COMPILER_ID}")
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "${CANON_CXX_COMPILER_FRONTEND_VARIANT}")
set(CMAKE_CXX_COMPILER_VERSION "${CANON_CXX_COMPILER_VERSION}")
set(CANON_GCOV_EXECUTABLE "")
set(CANON_LLVM_COV_EXECUTABLE "")

_canon_find_coverage_backend(_backend _reason)
if (NOT "${_backend}" STREQUAL "")
    message(FATAL_ERROR
        "failed automatic coverage discovery unexpectedly produced '${_backend}'")
endif()
if (NOT "${_reason}" MATCHES "did not report a usable")
    message(FATAL_ERROR
        "failed automatic coverage discovery did not explain the failure: '${_reason}'")
endif()
if (NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL ""
    OR NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR
        "automatic coverage discovery populated an explicit override variable")
endif()
return()
