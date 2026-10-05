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
    "${CANON_SOURCE_DIR}/test/vendored"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "Vendored Canon consumer configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Vendored Canon consumer build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "Vendored Canon consumer install"
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

set(_consumer_install "${_install_prefix}/share/canon-vendored-consumer/sample.cpp")
if(NOT EXISTS "${_consumer_install}")
    message(FATAL_ERROR "Vendored consumer install did not produce '${_consumer_install}'")
endif()

foreach(_canon_file IN ITEMS Canon.cmake CanonConfig.cmake CanonConfigVersion.cmake CanonCoverageClean.cmake)
    set(_installed_canon_file "${_install_prefix}/share/cmake/Canon/${_canon_file}")
    if(EXISTS "${_installed_canon_file}")
        message(FATAL_ERROR "Vendored Canon unexpectedly installed '${_installed_canon_file}'")
    endif()
endforeach()
