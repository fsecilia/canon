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
    "${CANON_SOURCE_DIR}/test/ipo/unavailable"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Release
)

canon_test_run(
    DESCRIPTION "IPO-unavailable configure"
    COMMAND ${_configure_command}
    EXPECTED_OUTPUT "Canon: IPO is unavailable; Release builds will continue without it"
)
canon_test_run(
    DESCRIPTION "IPO-unavailable build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}"
)
