# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CTEST_COMMAND
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

# A false, preseeded find_program result deterministically exercises the missing-gcovr path.
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCANON_GCOVR_EXECUTABLE:FILEPATH=FALSE
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
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Missing-gcovr fixture configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

set(_configure_output "${_configure_stdout}\n${_configure_stderr}")
foreach(_expected_fragment IN ITEMS
    "Canon coverage tests are disabled: gcovr was not found"
    "canon.integration.coverage"
    "canon.integration.coverage.empty-report"
    "canon.integration.presets.coverage"
)
    if (NOT "${_configure_output}" MATCHES "${_expected_fragment}")
        message(FATAL_ERROR
            "Canon configure did not report the expected disabled coverage diagnostic\n"
            "expected fragment:\n${_expected_fragment}\n"
            "stdout:\n${_configure_stdout}\n"
            "stderr:\n${_configure_stderr}")
    endif()
endforeach()

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        "-DCANON_CTEST_COMMAND=${CANON_CTEST_COMMAND}"
        "-DCANON_TEST_ROOT=${CANON_TEST_BINARY_DIR}"
        -DCANON_EXPECT_COVERAGE_ENABLED=FALSE
        -P "${CANON_SOURCE_DIR}/test/scripts/optional-tool-registration.cmake"
    RESULT_VARIABLE _registration_result
    OUTPUT_VARIABLE _registration_stdout
    ERROR_VARIABLE _registration_stderr
)
if (NOT "${_registration_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon did not disable coverage tests when gcovr was unavailable\n"
        "stdout:\n${_registration_stdout}\n"
        "stderr:\n${_registration_stderr}")
endif()
