# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_TEST_COMPILER_ID
    CANON_TEST_FRONTEND_VARIANT
    CANON_EXPECTED_ERROR
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/compiler-errors"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCANON_TEST_COMPILER_ID=${CANON_TEST_COMPILER_ID}"
    "-DCANON_TEST_FRONTEND_VARIANT=${CANON_TEST_FRONTEND_VARIANT}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)

if (_configure_result EQUAL 0)
    message(FATAL_ERROR
        "Unsupported compiler '${CANON_TEST_COMPILER_ID}' with frontend "
        "'${CANON_TEST_FRONTEND_VARIANT}' unexpectedly configured successfully")
endif()

set(_configure_output "${_configure_stdout}\n${_configure_stderr}")
string(FIND "${_configure_output}" "${CANON_EXPECTED_ERROR}" _expected_error_position)
if (_expected_error_position EQUAL -1)
    message(FATAL_ERROR
        "Unsupported compiler failed without the expected diagnostic\n"
        "expected fragment:\n${CANON_EXPECTED_ERROR}\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()
