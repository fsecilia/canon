# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CLANG_TIDY_EXECUTABLE
    CANON_GCOVR_EXECUTABLE
)

set(_fixture_root "${CANON_TEST_BINARY_DIR}-fixture")
set(_source_dir "${_fixture_root}/external/coverage")
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}" "${_fixture_root}")
file(MAKE_DIRECTORY "${_source_dir}")
file(COPY "${CANON_SOURCE_DIR}/test/coverage/project/" DESTINATION "${_source_dir}")

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
)
if(DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
endif()
if(DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
endif()

canon_test_run(
    DESCRIPTION "tidy with coverage configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "tidy with coverage build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "tidy with coverage tests"
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --build-config "${CANON_TEST_CONFIG}" --output-on-failure
)
canon_test_run(
    DESCRIPTION "tidy with coverage report"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}" --target coverage-report
)

set(_index "${CANON_TEST_BINARY_DIR}/coverage/index.html")
if(NOT EXISTS "${_index}")
    message(FATAL_ERROR "coverage-report did not generate ${_index}")
endif()
file(READ "${_index}" _html)
if(NOT "${_html}" MATCHES "covered\\.cpp")
    message(FATAL_ERROR "coverage report does not contain covered.cpp")
endif()
