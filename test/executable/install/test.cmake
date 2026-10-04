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
    "${CANON_SOURCE_DIR}/test/executable/install"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "Canon executable-install configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Canon executable-install build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "Canon executable-install install"
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

file(READ "${_build_dir}/installed-executable-name.txt" _executable_name)
string(STRIP "${_executable_name}" _executable_name)
set(_installed_executable "${_install_prefix}/bin/${_executable_name}")
if (NOT EXISTS "${_installed_executable}")
    message(FATAL_ERROR "Canon executable install did not produce '${_installed_executable}'")
endif()

canon_test_run(
    DESCRIPTION "installed Canon executable"
    COMMAND "${_installed_executable}"
)
