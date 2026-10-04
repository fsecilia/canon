# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation/unavailable")
set(_binary_dir "${CANON_TEST_BINARY_DIR}")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

canon_test_run(
    DESCRIPTION "documentation-unavailable fixture configure"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=TRUE
)
canon_test_run(
    DESCRIPTION "build without Doxygen"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "install without Doxygen"
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)
canon_test_run(
    DESCRIPTION "doc-clean without Doxygen"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --target doc-clean
)
canon_test_run(
    DESCRIPTION "doc target without Doxygen"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --target doc
    EXPECTED_OUTPUT
        "Doxygen 1.9 or newer was not found when this build tree was configured."
        "Install Doxygen 1.9 or newer and reconfigure before building the doc target."
)
