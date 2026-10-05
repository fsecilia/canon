# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_SOURCE_DIR)

canon_test_require_variables(
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CXX_COMPILER_ID
)

if("${CANON_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_override_variable CANON_GCOV_EXECUTABLE)
elseif("${CANON_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_override_variable CANON_LLVM_COV_EXECUTABLE)
else()
    message(FATAL_ERROR "unsupported test compiler '${CANON_CXX_COMPILER_ID}'")
endif()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/coverage/project"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
    "-D${_override_variable}=${CMAKE_COMMAND}"
)

canon_test_run(
    DESCRIPTION "invalid ${_override_variable} override"
    EXPECT_FAILURE
    COMMAND ${_configure_command}
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable: coverage override ${_override_variable}="
        "invalid:"
)
