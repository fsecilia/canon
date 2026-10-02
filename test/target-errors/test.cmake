# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_TEST_CASE
    CANON_EXPECTED_ERROR
)

set(_expected_output "${CANON_EXPECTED_ERROR}")
if (DEFINED CANON_EXPECTED_DETAIL AND NOT "${CANON_EXPECTED_DETAIL}" STREQUAL "")
    list(APPEND _expected_output "${CANON_EXPECTED_DETAIL}")
endif()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/target-errors"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCANON_TEST_CASE=${CANON_TEST_CASE}"
)

canon_test_run(
    DESCRIPTION "Canon target error case '${CANON_TEST_CASE}'"
    EXPECT_FAILURE
    EXPECTED_OUTPUT ${_expected_output}
    COMMAND ${_configure_command}
)
