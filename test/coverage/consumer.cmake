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
    -DCMAKE_INSTALL_LIBDIR=artifact-lib
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
    DESCRIPTION "coverage configure"
    COMMAND ${_configure_command}
)

file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}/stale")
file(WRITE "${CANON_TEST_BINARY_DIR}/stale/stale.gcda" "deliberately invalid stale data")
canon_test_run(
    DESCRIPTION "coverage clean"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}" --target coverage-clean
)
if (EXISTS "${CANON_TEST_BINARY_DIR}/stale/stale.gcda")
    message(FATAL_ERROR "coverage-clean left stale profile data behind")
endif()

canon_test_run(
    DESCRIPTION "coverage build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "coverage tests"
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --build-config "${CANON_TEST_CONFIG}" --output-on-failure
)

canon_test_run(
    DESCRIPTION "coverage report"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}" --target coverage-report
)

set(_index "${CANON_TEST_BINARY_DIR}/coverage/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "coverage-report did not generate ${_index}")
endif()
file(READ "${_index}" _html)
if (NOT "${_html}" MATCHES "covered\\.cpp")
    message(FATAL_ERROR "coverage report does not contain covered.cpp")
endif()
if ("${_html}" MATCHES "covered_test\\.cpp")
    message(FATAL_ERROR "coverage report unexpectedly contains covered_test.cpp")
endif()
if ("${_html}" MATCHES "excluded\\.cpp")
    message(FATAL_ERROR "coverage report unexpectedly contains external/excluded.cpp")
endif()

file(GLOB_RECURSE _remaining_gcda LIST_DIRECTORIES FALSE "${CANON_TEST_BINARY_DIR}/*.gcda")
if (_remaining_gcda)
    message(FATAL_ERROR "coverage-report left .gcda files behind: ${_remaining_gcda}")
endif()

set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
canon_test_run(
    DESCRIPTION "coverage install"
    COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
canon_test_make_configure_command(
    _consumer_configure_command
    "${CANON_SOURCE_DIR}/test/coverage/package-consumer"
    "${_consumer_build_dir}"
    "-DCanonCoverageFixture_DIR=${_install_prefix}/artifact-lib/cmake/CanonCoverageFixture"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "coverage package consumer configure"
    COMMAND ${_consumer_configure_command}
)
canon_test_run(
    DESCRIPTION "coverage package consumer build"
    COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_executable_path(_coverage_consumer "${_consumer_build_dir}" coverage_consumer)
canon_test_run(
    DESCRIPTION "coverage package consumer"
    COMMAND "${_coverage_consumer}"
)
