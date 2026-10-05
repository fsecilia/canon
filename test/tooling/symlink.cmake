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
file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}")

set(_symlink_root "${CANON_TEST_BINARY_DIR}/source")
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E create_symlink "${CANON_SOURCE_DIR}/test" "${_symlink_root}"
    RESULT_VARIABLE _symlink_result
    OUTPUT_VARIABLE _symlink_stdout
    ERROR_VARIABLE _symlink_stderr
)
if(NOT "${_symlink_result}" STREQUAL "0")
    message(FATAL_ERROR
        "create tidy source symlink failed with result '${_symlink_result}'\n"
        "stdout:\n${_symlink_stdout}\n"
        "stderr:\n${_symlink_stderr}")
endif()

set(_source_dir "${_symlink_root}/tooling")
set(_binary_dir "${CANON_TEST_BINARY_DIR}/build")
canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_binary_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
    -DCANON_ENABLE_TIDY=ON
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)

canon_test_run(
    DESCRIPTION "tidy configure through symlinked source tree"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "tidy build through symlinked source tree"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}"
)
