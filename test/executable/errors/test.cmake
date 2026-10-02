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

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/executable/errors"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCANON_TEST_CASE=${CANON_TEST_CASE}"
)

canon_test_run(
    DESCRIPTION "Canon executable error case '${CANON_TEST_CASE}'"
    EXPECT_FAILURE
    EXPECTED_OUTPUT "${CANON_EXPECTED_ERROR}"
    COMMAND ${_configure_command}
)
