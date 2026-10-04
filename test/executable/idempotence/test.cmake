# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/executable/idempotence"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "Canon executable idempotence configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Canon executable idempotence build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
)
canon_test_run(
    DESCRIPTION "Canon executable idempotence install"
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --prefix "${_install_prefix}"
)

file(STRINGS "${_build_dir}/install_manifest.txt" _installed_files)
set(_unique_installed_files "${_installed_files}")
list(REMOVE_DUPLICATES _unique_installed_files)
list(LENGTH _installed_files _installed_count)
list(LENGTH _unique_installed_files _unique_installed_count)
if (NOT "${_installed_count}" EQUAL "${_unique_installed_count}")
    message(FATAL_ERROR "canon_apply_executable() produced duplicate install rules when reapplied")
endif()
