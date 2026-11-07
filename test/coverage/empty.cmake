# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves the report fails when filtering leaves no project source, instead of producing an empty report.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/coverage/empty-report" BINARY "${_build}")
canon_test_build(BINARY "${_build}")
canon_test_execute(BINARY "${_build}" TARGET covered_empty)
canon_test_build(
    BINARY "${_build}"
    TARGET coverage-report
    EXPECT_FAILURE
    EXPECTED_OUTPUT "Canon coverage report contains no project source files"
)
