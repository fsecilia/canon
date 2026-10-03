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
    "${CANON_SOURCE_DIR}/test/policy"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)

canon_test_run(
    DESCRIPTION "Canon policy isolation configure"
    COMMAND ${_configure_command}
)
