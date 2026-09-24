# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(Canon VERSION 0.1.0 LANGUAGES NONE)

include(cmake/Canon.cmake)

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
