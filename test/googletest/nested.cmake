# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/googletest/nested"
    "${CANON_TEST_BINARY_DIR}/build"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)
canon_test_run(
    DESCRIPTION "Nested GoogleTest configure"
    EXPECTED_OUTPUT
        "finding dependency 'GTest' - using vendored 'googletest'"
        "finding dependency 'GTest' - already provided"
    COMMAND ${_configure_command}
)
