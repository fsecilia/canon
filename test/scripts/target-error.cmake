# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_TEST_CASE
    CANON_EXPECTED_ERROR
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/target-errors"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCANON_TEST_CASE=${CANON_TEST_CASE}"
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)

if (_configure_result EQUAL 0)
    message(FATAL_ERROR "Canon target error case '${CANON_TEST_CASE}' unexpectedly configured successfully")
endif()

set(_configure_output "${_configure_stdout}\n${_configure_stderr}")
set(_expected_errors "${CANON_EXPECTED_ERROR}")
if (DEFINED CANON_EXPECTED_DETAIL AND NOT "${CANON_EXPECTED_DETAIL}" STREQUAL "")
    list(APPEND _expected_errors "${CANON_EXPECTED_DETAIL}")
endif()

foreach(_expected_error IN LISTS _expected_errors)
    string(FIND "${_configure_output}" "${_expected_error}" _expected_error_position)
    if (_expected_error_position EQUAL -1)
        message(FATAL_ERROR
            "Canon target error case '${CANON_TEST_CASE}' failed without the expected diagnostic\n"
            "expected fragment:\n${_expected_error}\n"
            "stdout:\n${_configure_stdout}\n"
            "stderr:\n${_configure_stderr}")
    endif()
endforeach()
