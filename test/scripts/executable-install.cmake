# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Validate the inputs supplied by Canon's executable-install integration test.
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

# Start the executable-install lifecycle from clean build and install trees.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/executable-install"
    -B "${CANON_TEST_BINARY_DIR}/build"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

# Configure the executable fixture and retain output for a useful failure report.
execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Canon executable-install configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# Build the executable before installing it.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}/build"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT _build_result EQUAL 0)
    message(FATAL_ERROR
        "Canon executable-install build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Install through the same lifecycle used by a real consumer project.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${CANON_TEST_BINARY_DIR}/build"
        --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT _install_result EQUAL 0)
    message(FATAL_ERROR
        "Canon executable-install install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

# Resolve the generator-specific executable filename recorded by the fixture.
file(READ "${CANON_TEST_BINARY_DIR}/build/installed-executable-name.txt" _executable_name)
string(STRIP "${_executable_name}" _executable_name)
set(_installed_executable "${_install_prefix}/bin/${_executable_name}")
if (NOT EXISTS "${_installed_executable}")
    message(FATAL_ERROR "Canon executable install did not produce '${_installed_executable}'")
endif()

# Run the installed executable so the test checks the installed artifact itself.
execute_process(
    COMMAND "${_installed_executable}"
    RESULT_VARIABLE _run_result
    OUTPUT_VARIABLE _run_stdout
    ERROR_VARIABLE _run_stderr
)
if (NOT _run_result EQUAL 0)
    message(FATAL_ERROR
        "Installed Canon executable failed (${_run_result})\n"
        "stdout:\n${_run_stdout}\n"
        "stderr:\n${_run_stderr}")
endif()
