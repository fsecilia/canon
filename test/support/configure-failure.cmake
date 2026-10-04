# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_FIXTURE_SOURCE_DIR
    CANON_EXPECTED_ERROR
)

set(_expected_output "${CANON_EXPECTED_ERROR}")
foreach(_optional_variable IN ITEMS CANON_EXPECTED_DETAIL CANON_EXPECTED_STATUS)
    if (DEFINED ${_optional_variable} AND NOT "${${_optional_variable}}" STREQUAL "")
        list(APPEND _expected_output "${${_optional_variable}}")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

canon_test_make_configure_command(
    _configure_command
    "${CANON_FIXTURE_SOURCE_DIR}"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)

canon_test_run(
    DESCRIPTION "Canon configure-failure fixture '${CANON_FIXTURE_SOURCE_DIR}'"
    EXPECT_FAILURE
    EXPECTED_OUTPUT ${_expected_output}
    COMMAND ${_configure_command}
)
