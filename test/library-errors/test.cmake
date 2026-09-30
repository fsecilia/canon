# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_FIXTURE
    CANON_EXPECTED_ERROR
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

canon_test_run(
    DESCRIPTION "Canon library error fixture '${CANON_FIXTURE}'"
    EXPECT_FAILURE
    NORMALIZE_WHITESPACE
    EXPECTED_OUTPUT "${CANON_EXPECTED_ERROR}"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/library-errors/${CANON_FIXTURE}"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)
