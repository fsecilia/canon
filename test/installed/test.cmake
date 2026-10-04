# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_EXPECTED_VERSION
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_canon_build_dir "${CANON_TEST_BINARY_DIR}/canon-build")
set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/consumer-build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_data_dir artifact-data)
set(_canon_package_dir "${_install_prefix}/${_data_dir}/cmake/Canon")

canon_test_make_configure_command(
    _staging_configure_command
    "${CANON_SOURCE_DIR}"
    "${_canon_build_dir}"
    -DBUILD_TESTING=OFF
    "-DCMAKE_INSTALL_DATADIR=${_data_dir}"
)
canon_test_run(
    DESCRIPTION "Canon staging configure"
    COMMAND ${_staging_configure_command}
)
canon_test_run(
    DESCRIPTION "Canon staging install"
    COMMAND "${CMAKE_COMMAND}" --install "${_canon_build_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

set(_coverage_clean_script "${_canon_package_dir}/CanonCoverageClean.cmake")
if (NOT EXISTS "${_coverage_clean_script}")
    message(FATAL_ERROR "Canon install did not include '${_coverage_clean_script}'")
endif()

set(_minimum_version_probe "${CANON_TEST_BINARY_DIR}/minimum-version.cmake")
file(WRITE "${_minimum_version_probe}" [=[
set(CMAKE_VERSION 3.30.0)
include("${CANON_CONFIG_FILE}")
]=])
canon_test_run(
    DESCRIPTION "Installed Canon CMake minimum"
    EXPECT_FAILURE
    COMMAND
        "${CMAKE_COMMAND}"
        "-DCANON_CONFIG_FILE=${_canon_package_dir}/CanonConfig.cmake"
        -P "${_minimum_version_probe}"
    EXPECTED_OUTPUT "Canon requires CMake 3.31.6 or newer; found 3.30.0"
)

canon_test_make_configure_command(
    _consumer_configure_command
    "${CANON_SOURCE_DIR}/test/installed"
    "${_consumer_build_dir}"
    "-DCANON_EXPECTED_VERSION=${CANON_EXPECTED_VERSION}"
    "-DCANON_EXPECTED_DIR=${_canon_package_dir}"
    "-DCanon_DIR=${_canon_package_dir}"
    "-DCMAKE_PREFIX_PATH=${_install_prefix}"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "Installed Canon consumer configure"
    COMMAND ${_consumer_configure_command}
)
canon_test_run(
    DESCRIPTION "Installed Canon consumer build"
    COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}" --config "${CANON_TEST_CONFIG}"
)
