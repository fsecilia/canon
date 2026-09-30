# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Validate the inputs supplied by Canon's integration-test registration.
foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_GCOVR_EXECUTABLE
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Place the source below an ancestor named external while keeping the build tree outside it.
set(_fixture_root "${CANON_TEST_BINARY_DIR}-fixture")
set(_source_dir "${_fixture_root}/external/coverage")
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}" "${_fixture_root}")
file(MAKE_DIRECTORY "${_source_dir}")
file(COPY "${CANON_SOURCE_DIR}/test/coverage/" DESTINATION "${_source_dir}")

# Configure the fixture with the active compiler, toolchain, and validated coverage tools.
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${_source_dir}"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCMAKE_INSTALL_LIBDIR=artifact-lib
    -DCANON_ENABLE_COVERAGE=ON
    "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()
if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
endif()
if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
endif()

# Configure the fixture and retain output for a useful failure report.
execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# Prove the cleanup target removes stale profile data before the build starts.
file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}/stale")
file(WRITE "${CANON_TEST_BINARY_DIR}/stale/stale.gcda" "deliberately invalid stale data")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-clean
    RESULT_VARIABLE _clean_result
    OUTPUT_VARIABLE _clean_stdout
    ERROR_VARIABLE _clean_stderr
)
if (NOT "${_clean_result}" EQUAL 0 OR EXISTS "${CANON_TEST_BINARY_DIR}/stale/stale.gcda")
    message(FATAL_ERROR
        "coverage-clean failed\n"
        "stdout:\n${_clean_stdout}\n"
        "stderr:\n${_clean_stderr}")
endif()

# Build the instrumented fixture before allowing the project to run its own tests.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT "${_build_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Run CTest separately and require the project-owned non-target test to participate.
execute_process(
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --output-on-failure
    RESULT_VARIABLE _test_result
    OUTPUT_VARIABLE _test_stdout
    ERROR_VARIABLE _test_stderr
)
if (NOT "${_test_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage tests failed\n"
        "stdout:\n${_test_stdout}\n"
        "stderr:\n${_test_stderr}")
endif()
string(FIND "${_test_stdout}" "coverage_project_owned" _project_owned_position)
if ("${_project_owned_position}" EQUAL -1)
    message(FATAL_ERROR "CTest did not run the project-owned coverage test")
endif()

# Generate the HTML report and retain output so backend failures remain visible.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-report
    RESULT_VARIABLE _report_result
    OUTPUT_VARIABLE _report_stdout
    ERROR_VARIABLE _report_stderr
)
if (NOT "${_report_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage-report failed\n"
        "stdout:\n${_report_stdout}\n"
        "stderr:\n${_report_stderr}")
endif()

# Verify the report contains project code, applies both exclusions, and removes runtime data.
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

# Install the instrumented archive and prove its exported link requirement works downstream.
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}" --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT "${_install_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
set(_consumer_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/coverage-package-consumer"
    -B "${_consumer_build_dir}"
    -G "${CANON_GENERATOR}"
    "-DCanonCoverageFixture_DIR=${_install_prefix}/artifact-lib/cmake/CanonCoverageFixture"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_consumer_configure_command}
    RESULT_VARIABLE _consumer_configure_result
    OUTPUT_VARIABLE _consumer_configure_stdout
    ERROR_VARIABLE _consumer_configure_stderr
)
if (NOT "${_consumer_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage package consumer configure failed\n"
        "stdout:\n${_consumer_configure_stdout}\n"
        "stderr:\n${_consumer_configure_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}"
    RESULT_VARIABLE _consumer_build_result
    OUTPUT_VARIABLE _consumer_build_stdout
    ERROR_VARIABLE _consumer_build_stderr
)
if (NOT "${_consumer_build_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage package consumer build failed\n"
        "stdout:\n${_consumer_build_stdout}\n"
        "stderr:\n${_consumer_build_stderr}")
endif()

execute_process(
    COMMAND "${_consumer_build_dir}/coverage_consumer"
    RESULT_VARIABLE _consumer_run_result
    OUTPUT_VARIABLE _consumer_run_stdout
    ERROR_VARIABLE _consumer_run_stderr
)
if (NOT "${_consumer_run_result}" EQUAL 0)
    message(FATAL_ERROR
        "coverage package consumer failed\n"
        "stdout:\n${_consumer_run_stdout}\n"
        "stderr:\n${_consumer_run_stderr}")
endif()
