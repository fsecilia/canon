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

_canon_validate_coverage_version_output(
    "gcov (GCC) 14.3.0\n"
    GNU
    14
    _valid
    _reason
)
if (NOT _valid)
    message(FATAL_ERROR "matching GNU gcov version was rejected: ${_reason}")
endif()

_canon_validate_coverage_version_output(
    "gcov (GCC) 14.3.0\n"
    GNU
    15
    _valid
    _reason
)
if (_valid OR NOT "${_reason}" MATCHES "reports major version 14")
    message(FATAL_ERROR "GNU gcov major-version mismatch was not diagnosed")
endif()

_canon_validate_coverage_version_output(
    "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
    LLVM
    17
    _valid
    _reason
)
if (NOT _valid)
    message(FATAL_ERROR "matching LLVM llvm-cov version was rejected: ${_reason}")
endif()

_canon_validate_coverage_version_output(
    "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
    GNU
    17
    _valid
    _reason
)
if (_valid OR NOT "${_reason}" MATCHES "GNU gcov")
    message(FATAL_ERROR "coverage-tool family mismatch was not diagnosed")
endif()

_canon_resolve_reported_coverage_tool(
    canon-nonexistent-coverage-companion
    _resolved_executable
)
if (NOT "${_resolved_executable}" STREQUAL "")
    message(FATAL_ERROR
        "coverage discovery unexpectedly resolved '${_resolved_executable}' for a missing exact name")
endif()

canon_test_run(
    DESCRIPTION "coverage-backend unavailable probe"
    COMMAND
        "${CMAKE_COMMAND}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCANON_TEST_BINARY_DIR=${CANON_TEST_BINARY_DIR}"
        "-DCANON_CXX_COMPILER_ID=${CANON_CXX_COMPILER_ID}"
        "-DCANON_CXX_COMPILER_FRONTEND_VARIANT=${CANON_CXX_COMPILER_FRONTEND_VARIANT}"
        "-DCANON_CXX_COMPILER_VERSION=${CANON_CXX_COMPILER_VERSION}"
        -P "${CANON_SOURCE_DIR}/test/coverage/backend-unavailable.cmake"
    EXPECTED_OUTPUT "did not report a usable"
)
