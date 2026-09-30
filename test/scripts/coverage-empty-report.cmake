# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

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

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/coverage-empty"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
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

execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "empty coverage configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT "${_build_result}" EQUAL 0)
    message(FATAL_ERROR
        "empty coverage build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

execute_process(
    COMMAND "${CANON_TEST_BINARY_DIR}/covered_empty"
    RESULT_VARIABLE _run_result
    OUTPUT_VARIABLE _run_stdout
    ERROR_VARIABLE _run_stderr
)
if (NOT "${_run_result}" EQUAL 0)
    message(FATAL_ERROR
        "empty coverage fixture failed\n"
        "stdout:\n${_run_stdout}\n"
        "stderr:\n${_run_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-report
    RESULT_VARIABLE _report_result
    OUTPUT_VARIABLE _report_stdout
    ERROR_VARIABLE _report_stderr
)
if ("${_report_result}" EQUAL 0)
    message(FATAL_ERROR "coverage-report unexpectedly accepted a report with no source files")
endif()
set(_report_output "${_report_stdout}\n${_report_stderr}")
if (NOT "${_report_output}" MATCHES "Canon coverage report contains no project source files")
    message(FATAL_ERROR
        "coverage-report failed for the wrong reason\n"
        "stdout:\n${_report_stdout}\n"
        "stderr:\n${_report_stderr}")
endif()
