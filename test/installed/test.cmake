# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Installs Canon, then consumes the installed package the way downstream projects do.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_EXPECTED_VERSION CANON_GTEST_PACKAGE_DIR)

set(_canon_build "${CANON_TEST_BINARY_DIR}/canon-build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_data_dir artifact-data)
set(_package_dir "${_prefix}/${_data_dir}/cmake/Canon")

canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}"
    BINARY "${_canon_build}"
    ARGS -DBUILD_TESTING=OFF "-DCMAKE_INSTALL_DATADIR=${_data_dir}"
)
canon_test_install(BINARY "${_canon_build}" PREFIX "${_prefix}")
foreach(_file IN ITEMS Canon.cmake CanonConfig.cmake CanonConfigVersion.cmake CanonCoverageClean.cmake
    CanonCoverageVerify.cmake
)
    canon_test_require_paths("${_package_dir}/${_file}")
endforeach()
# Canon does not install GoogleTest with itself.
canon_test_forbid_paths("${_prefix}/include/gtest" "${_prefix}/include/gmock" "${_prefix}/lib/cmake/GTest")

set(_minimum_version_probe "${CANON_TEST_BINARY_DIR}/minimum-version.cmake")
file(WRITE "${_minimum_version_probe}" "set(CMAKE_VERSION 3.30.0)\ninclude(\"${_package_dir}/CanonConfig.cmake\")\n")
canon_test_run(
    DESCRIPTION "installed Canon rejects an older CMake"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" -P "${_minimum_version_probe}"
    EXPECTED_OUTPUT "Canon requires CMake 3.31.6 or newer; found 3.30.0"
)

set(_consumer_arguments
    "-DCANON_EXPECTED_VERSION=${CANON_EXPECTED_VERSION}"
    "-DCANON_EXPECTED_DIR=${_package_dir}"
    "-DCanon_DIR=${_package_dir}"
)
set(_consumer "${CANON_TEST_BINARY_DIR}/consumer")
canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/installed" BINARY "${_consumer}" ARGS ${_consumer_arguments})
canon_test_build(BINARY "${_consumer}")

# Without its source checkout, installed Canon falls back to an installed GoogleTest package.
set(_googletest_consumer "${CANON_TEST_BINARY_DIR}/googletest-consumer")
canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/installed"
    BINARY "${_googletest_consumer}"
    DESCRIPTION "installed Canon finds an installed GoogleTest"
    ARGS ${_consumer_arguments} -DCANON_TEST_REQUIRE_GOOGLETEST=ON "-DGTest_DIR=${CANON_GTEST_PACKAGE_DIR}"
    EXPECTED_OUTPUT "finding dependency 'GTest' - using installed package 'GTest'"
)
