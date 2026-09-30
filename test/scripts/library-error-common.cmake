# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

foreach(_required_variable _canon_fixture _canon_expected_error)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Start each negative configure from a clean build tree.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

# Configure the invalid fixture; success is the failure condition for this test.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/library-errors/${_canon_fixture}"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)

if ("${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon library error fixture '${_canon_fixture}' unexpectedly configured successfully")
endif()

# Require the failed configure to report the public contract diagnostic.
set(_configure_output "${_configure_stdout}\n${_configure_stderr}")
string(REGEX REPLACE "[ \t\r\n]+" " " _normalized_output "${_configure_output}")
string(REGEX REPLACE "[ \t\r\n]+" " " _normalized_expected "${_canon_expected_error}")
string(FIND "${_normalized_output}" "${_normalized_expected}" _expected_error_position)
if ("${_expected_error_position}" EQUAL -1)
    message(FATAL_ERROR
        "Canon library error fixture '${_canon_fixture}' failed without the expected diagnostic\n"
        "expected fragment:\n${_canon_expected_error}\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()
