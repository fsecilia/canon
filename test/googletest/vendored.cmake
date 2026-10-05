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
    "${CANON_SOURCE_DIR}/test/googletest/vendored"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)
canon_test_run(
    DESCRIPTION "Vendored Canon GoogleTest configure"
    EXPECTED_OUTPUT "finding dependency 'GTest' - using vendored 'googletest'"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Vendored Canon GoogleTest install"
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

set(_marker "${_install_prefix}/share/canon-gtest-fixture/installed-marker.txt")
if(NOT EXISTS "${_marker}")
    message(FATAL_ERROR "GoogleTest fixture install did not produce '${_marker}'")
endif()
foreach(_unexpected_path IN ITEMS
    "${_install_prefix}/include/gtest"
    "${_install_prefix}/include/gmock"
    "${_install_prefix}/lib/cmake/GTest"
    "${_install_prefix}/lib/libgtest.a"
    "${_install_prefix}/lib/libgmock.a"
)
    if(EXISTS "${_unexpected_path}")
        message(FATAL_ERROR "Canon's vendored GoogleTest unexpectedly installed '${_unexpected_path}'")
    endif()
endforeach()
