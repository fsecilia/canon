# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_SOURCE_DIR)

canon_test_require_variables(
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_GCOVR_EXECUTABLE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/coverage-nested"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
    "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
)
if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
endif()
if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
endif()

canon_test_run(
    DESCRIPTION "nested coverage configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "nested coverage build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
)
canon_test_run(
    DESCRIPTION "nested coverage tests"
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --output-on-failure
)
canon_test_run(
    DESCRIPTION "nested coverage report"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-report
)

set(_index "${CANON_TEST_BINARY_DIR}/coverage/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "nested coverage-report did not generate ${_index}")
endif()
file(READ "${_index}" _html)
if (NOT "${_html}" MATCHES "covered\\.cpp")
    message(FATAL_ERROR
        "coverage report suppressed project source beneath an ancestor external directory")
endif()
if ("${_html}" MATCHES "excluded\\.cpp")
    message(FATAL_ERROR
        "coverage report unexpectedly contains the active project's external/excluded.cpp")
endif()
