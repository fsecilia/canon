# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

# Use CMake itself as a deterministic executable whose version is below the tidy floor.
set(_unsupported_tidy "${CMAKE_COMMAND}")

# A project that enables tidy must reject the unsupported executable during configuration.
set(_consumer_binary_dir "${CANON_TEST_BINARY_DIR}/consumer")
set(_consumer_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/tooling"
    -B "${_consumer_binary_dir}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${_unsupported_tidy}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_consumer_configure_command}
    RESULT_VARIABLE _consumer_result
    OUTPUT_VARIABLE _consumer_stdout
    ERROR_VARIABLE _consumer_stderr
)
if ("${_consumer_result}" EQUAL 0)
    message(FATAL_ERROR "unsupported clang-tidy unexpectedly configured successfully")
endif()

set(_consumer_output "${_consumer_stdout}\n${_consumer_stderr}")
if (NOT "${_consumer_output}" MATCHES "requires clang-tidy 21\\.1\\.6 or newer")
    message(FATAL_ERROR
        "unsupported clang-tidy failed without the expected diagnostic\n"
        "stdout:\n${_consumer_stdout}\n"
        "stderr:\n${_consumer_stderr}")
endif()

# Canon's own harness treats the same executable as unavailable.
set(_harness_binary_dir "${CANON_TEST_BINARY_DIR}/harness")
set(_harness_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}"
    -B "${_harness_binary_dir}"
    -G "${CANON_GENERATOR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    "-DCANON_CLANG_TIDY_EXECUTABLE=${_unsupported_tidy}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _harness_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_harness_configure_command}
    RESULT_VARIABLE _harness_result
    OUTPUT_VARIABLE _harness_stdout
    ERROR_VARIABLE _harness_stderr
)
if (NOT "${_harness_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon harness configure failed for an unsupported optional clang-tidy\n"
        "stdout:\n${_harness_stdout}\n"
        "stderr:\n${_harness_stderr}")
endif()

set(_harness_output "${_harness_stdout}\n${_harness_stderr}")
if (NOT "${_harness_output}" MATCHES "clang-tidy validation unavailable: clang-tidy [0-9.]+"
    OR NOT "${_harness_output}" MATCHES "required minimum 21\.1\.6")
    message(FATAL_ERROR
        "Canon harness did not report the unsupported clang-tidy version\n${_harness_output}")
endif()

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        "-DCANON_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}"
        "-DCANON_TEST_ROOT=${_harness_binary_dir}"
        -DCANON_EXPECT_TIDY_ENABLED=FALSE
        -P "${CANON_SOURCE_DIR}/test/scripts/optional-tool-registration.cmake"
    RESULT_VARIABLE _registration_result
    OUTPUT_VARIABLE _registration_stdout
    ERROR_VARIABLE _registration_stderr
)
if (NOT "${_registration_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon harness did not disable tests for the unsupported clang-tidy
"
        "stdout:
${_registration_stdout}
"
        "stderr:
${_registration_stderr}")
endif()
