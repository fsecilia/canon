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

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/ipo-unavailable"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Release
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

canon_test_run(
    DESCRIPTION "IPO-unavailable configure"
    COMMAND ${_configure_command}
    EXPECTED_OUTPUT "Canon: IPO is unavailable; Release builds will continue without it"
)
canon_test_run(
    DESCRIPTION "IPO-unavailable build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
)
