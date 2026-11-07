# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves clang-tidy runs on managed targets with Canon's warning policy and skips headers under external/.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/tooling" BINARY "${_build}")
canon_test_build(BINARY "${_build}" DESCRIPTION "tidy build with an external header")
canon_test_build(BINARY "${_build}" TARGET tidy_warning_policy)
canon_test_build(
    BINARY "${_build}"
    TARGET tidy_probe
    DESCRIPTION "tidy rejects a managed naming violation"
    EXPECT_FAILURE
    EXPECTED_OUTPUT readability-identifier-naming
)

# Only the project's own external/ is excluded, so its headers are still checked beneath an ancestor's external/.
set(_nested_source "${CANON_TEST_BINARY_DIR}/nested-source/external/tooling")
set(_nested_build "${CANON_TEST_BINARY_DIR}/nested-build")
file(COPY "${CANON_SOURCE_DIR}/test/tooling/" DESTINATION "${_nested_source}")
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_nested_source}")
canon_test_configure(SOURCE "${_nested_source}" BINARY "${_nested_build}")
canon_test_build(
    BINARY "${_nested_build}"
    TARGET tidy_header_probe
    DESCRIPTION "tidy checks a project header beneath an ancestor external/ directory"
    EXPECT_FAILURE
    EXPECTED_OUTPUT readability-identifier-naming
)
