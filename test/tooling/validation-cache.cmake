# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CLANG_TIDY_EXECUTABLE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

set(_consumer_binary_dir "${CANON_TEST_BINARY_DIR}/consumer")
canon_test_make_configure_command(
    _consumer_configure_command
    "${CANON_SOURCE_DIR}/test/tooling"
    "${_consumer_binary_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    "-DCANON_SECOND_CLANG_TIDY_EXECUTABLE=${CMAKE_COMMAND}"
)

canon_test_run(
    DESCRIPTION "revalidate a different clang-tidy executable"
    EXPECT_FAILURE
    COMMAND ${_consumer_configure_command}
    EXPECTED_REGEX "requires clang-tidy 21\\.1\\.6 or newer"
)
