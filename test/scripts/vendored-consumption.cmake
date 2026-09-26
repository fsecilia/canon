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

# Start the vendored consumer from clean build and install trees.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/vendored"
    -B "${CANON_TEST_BINARY_DIR}/build"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

# configure
execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Vendored Canon consumer configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# build
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}/build"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT _build_result EQUAL 0)
    message(FATAL_ERROR
        "Vendored Canon consumer build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# install
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}/build" --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT _install_result EQUAL 0)
    message(FATAL_ERROR
        "Vendored Canon consumer install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

set(_consumer_install "${_install_prefix}/share/canon-vendored-consumer/sample.cpp")
if (NOT EXISTS "${_consumer_install}")
    message(FATAL_ERROR "Vendored consumer install did not produce '${_consumer_install}'")
endif()

foreach(_canon_file IN ITEMS Canon.cmake CanonConfig.cmake CanonConfigVersion.cmake)
    set(_installed_canon_file "${_install_prefix}/share/cmake/Canon/${_canon_file}")
    if (EXISTS "${_installed_canon_file}")
        message(FATAL_ERROR "Vendored Canon unexpectedly installed '${_installed_canon_file}'")
    endif()
endforeach()
