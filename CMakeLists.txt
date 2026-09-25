# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(Canon VERSION 0.1.0 LANGUAGES NONE)

include(cmake/Canon.cmake)

# Keep Canon's development setup out of projects that vendor it as a subdirectory.
if (NOT PROJECT_IS_TOP_LEVEL)
    return()
endif()

install(FILES cmake/Canon.cmake DESTINATION share/cmake/Canon)

include(CTest)
if (NOT BUILD_TESTING)
    return()
endif()

enable_language(CXX)

function(_canon_add_script_test NAME SCRIPT)
    add_test(
        NAME "canon.integration.${NAME}"
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DCANON_TEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/test/${NAME}"
            "-DCANON_GENERATOR=${CMAKE_GENERATOR}"
            "-DCANON_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            "-DCANON_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
            ${ARGN}
            -P "${CMAKE_CURRENT_SOURCE_DIR}/test/scripts/${SCRIPT}"
    )
    set_tests_properties("canon.integration.${NAME}" PROPERTIES LABELS integration TIMEOUT 120)
endfunction()

_canon_add_script_test(
    targets
    target-consumer.cmake
    -DCANON_BUILD_TYPE=Debug
)

_canon_add_script_test(
    targets.release
    target-consumer.cmake
    -DCANON_BUILD_TYPE=Release
)

_canon_add_script_test(
    targets.missing
    target-error.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=target 'missing' does not exist"
)

_canon_add_script_test(
    targets.interface
    target-error.cmake
    -DCANON_TEST_CASE=interface
    "-DCANON_EXPECTED_ERROR=target 'sample_interface' has type"
    "-DCANON_EXPECTED_DETAIL='INTERFACE_LIBRARY'"
)
