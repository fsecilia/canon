# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CXX_COMPILER_ID
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

if ("${CANON_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_override_variable CANON_GCOV_EXECUTABLE)
elseif ("${CANON_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_override_variable CANON_LLVM_COV_EXECUTABLE)
else()
    message(FATAL_ERROR "unsupported test compiler '${CANON_CXX_COMPILER_ID}'")
endif()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/coverage"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
    "-D${_override_variable}=${CMAKE_COMMAND}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
)
if (_result EQUAL 0)
    message(FATAL_ERROR "invalid ${_override_variable} unexpectedly configured successfully")
endif()

set(_output "${_stdout}\n${_stderr}")
string(FIND "${_output}" "Canon coverage override ${_override_variable}=" _override_position)
string(FIND "${_output}" "invalid:" _invalid_position)
if (_override_position EQUAL -1 OR _invalid_position EQUAL -1)
    message(FATAL_ERROR
        "invalid ${_override_variable} failed for the wrong reason\n"
        "stdout:\n${_stdout}\n"
        "stderr:\n${_stderr}")
endif()
