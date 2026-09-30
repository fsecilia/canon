# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_FIXTURE
    CANON_EXPECTED_ERROR
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Start each executable error case from a clean build tree.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

# Configure the invalid fixture; success is the failure condition for this test.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/executable-errors/${CANON_FIXTURE}"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if ("${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon executable error case '${CANON_FIXTURE}' unexpectedly configured successfully")
endif()

# Check the configure failure for the public API diagnostic.
set(_configure_output "${_configure_stdout}\n${_configure_stderr}")
string(FIND "${_configure_output}" "${CANON_EXPECTED_ERROR}" _expected_error_position)
if ("${_expected_error_position}" EQUAL -1)
    message(FATAL_ERROR
        "Canon executable error case '${CANON_FIXTURE}' failed without the expected diagnostic\n"
        "expected fragment:\n${CANON_EXPECTED_ERROR}\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()
