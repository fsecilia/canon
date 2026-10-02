# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CLANG_TIDY_EXECUTABLE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/tooling"
    "${CANON_TEST_BINARY_DIR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)

canon_test_run(
    DESCRIPTION "tidy configure"
    COMMAND ${_configure_command}
)

set(_nested_root "${CANON_TEST_BINARY_DIR}/nested-source")
set(_nested_source_dir "${_nested_root}/external/tooling")
set(_nested_binary_dir "${CANON_TEST_BINARY_DIR}/nested-build")
file(MAKE_DIRECTORY "${_nested_root}/external")
file(COPY "${CANON_SOURCE_DIR}/test/tooling/" DESTINATION "${_nested_source_dir}")
file(COPY "${CANON_SOURCE_DIR}/test/support" DESTINATION "${_nested_root}/external")
configure_file(
    "${CANON_SOURCE_DIR}/.clang-tidy"
    "${_nested_source_dir}/.clang-tidy"
    COPYONLY
)

canon_test_make_configure_command(
    _nested_configure_command
    "${_nested_source_dir}"
    "${_nested_binary_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)

canon_test_run(
    DESCRIPTION "tidy configure beneath ancestor external directory"
    COMMAND ${_nested_configure_command}
)
canon_test_run(
    DESCRIPTION "project header beneath ancestor external directory"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" --build "${_nested_binary_dir}" --target tidy_header_probe
    EXPECTED_OUTPUT readability-identifier-naming
)
canon_test_run(
    DESCRIPTION "tidy build with managed external header"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
)
canon_test_run(
    DESCRIPTION "deliberately invalid managed tidy target"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target tidy_probe
    EXPECTED_OUTPUT readability-identifier-naming
)
