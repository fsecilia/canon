# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_BUILD_TYPE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/consumer"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    "-DCMAKE_BUILD_TYPE=${CANON_BUILD_TYPE}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()
if (DEFINED CANON_ENABLE_WARNINGS)
    list(APPEND _configure_command "-DCANON_ENABLE_WARNINGS=${CANON_ENABLE_WARNINGS}")
endif()

canon_test_run(
    DESCRIPTION "Canon consumer configure (${CANON_BUILD_TYPE})"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Canon consumer build (${CANON_BUILD_TYPE})"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
)
canon_test_run(
    DESCRIPTION "exported visibility probe"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target visibility_exported
)
canon_test_run(
    DESCRIPTION "unexported visibility probe"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target visibility_hidden
    EXPECTED_OUTPUT sampleHiddenAnswer
    EXPECTED_REGEX "undefined reference|undefined symbol|Undefined symbols|unresolved external symbol"
)

if (CANON_ENABLE_WARNINGS)
    canon_test_run(
        DESCRIPTION "Canon warning probe with warnings enabled"
        EXPECT_FAILURE
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target warning_probe
    )
    canon_test_run(
        DESCRIPTION "Canon warning probe with unused-parameter demoted"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target warning_probe_demoted
    )
else()
    canon_test_run(
        DESCRIPTION "Canon warning probe with warnings disabled"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target warning_probe
    )
endif()
