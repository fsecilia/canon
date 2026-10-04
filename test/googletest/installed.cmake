# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")
include(CMakePackageConfigHelpers)

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
set(_canon_package_dir "${_install_prefix}/share/cmake/Canon")
set(_gtest_package_dir "${CANON_TEST_BINARY_DIR}/gtest-package/GTest")

canon_test_make_configure_command(
    _canon_configure_command
    "${CANON_SOURCE_DIR}"
    "${_canon_build_dir}"
    -DBUILD_TESTING=OFF
)
canon_test_run(
    DESCRIPTION "Installed GoogleTest policy Canon configure"
    COMMAND ${_canon_configure_command}
)
canon_test_run(
    DESCRIPTION "Installed GoogleTest policy Canon install"
    COMMAND "${CMAKE_COMMAND}" --install "${_canon_build_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_install_prefix}"
)

foreach(_unexpected_path IN ITEMS
    "${_install_prefix}/include/gtest"
    "${_install_prefix}/include/gmock"
    "${_install_prefix}/lib/cmake/GTest"
    "${_install_prefix}/lib/libgtest.a"
    "${_install_prefix}/lib/libgmock.a"
    "${_install_prefix}/share/cmake/external/googletest"
)
    if (EXISTS "${_unexpected_path}")
        message(FATAL_ERROR "Installed Canon unexpectedly included GoogleTest at '${_unexpected_path}'")
    endif()
endforeach()

file(MAKE_DIRECTORY "${_gtest_package_dir}")
file(WRITE "${_gtest_package_dir}/GTestConfig.cmake" [=[
if (NOT "${GTest_FIND_VERSION_RANGE}" STREQUAL "1.18.0...<2.0.0")
    message(FATAL_ERROR "GTest received version range '${GTest_FIND_VERSION_RANGE}'")
endif()
add_library(GTest::gmock_main INTERFACE IMPORTED)
add_library(GTest::gtest_main INTERFACE IMPORTED)
]=])
write_basic_package_version_file(
    "${_gtest_package_dir}/GTestConfigVersion.cmake"
    VERSION 1.18.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

canon_test_make_configure_command(
    _consumer_configure_command
    "${CANON_SOURCE_DIR}/test/googletest/installed"
    "${_consumer_build_dir}"
    "-DCANON_EXPECTED_VERSION=${CANON_EXPECTED_VERSION}"
    "-DCANON_EXPECTED_DIR=${_canon_package_dir}"
    "-DCanon_DIR=${_canon_package_dir}"
    "-DGTest_DIR=${_gtest_package_dir}"
)
canon_test_run(
    DESCRIPTION "Installed Canon GoogleTest consumer configure"
    EXPECTED_OUTPUT "finding dependency 'GTest' - using installed package 'GTest'"
    COMMAND ${_consumer_configure_command}
)
