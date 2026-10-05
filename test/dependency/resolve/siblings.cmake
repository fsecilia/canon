# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")
include(CMakePackageConfigHelpers)

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_package_dir "${CANON_TEST_BINARY_DIR}/package/DependencyFixture")
file(MAKE_DIRECTORY
    "${_source_dir}/first"
    "${_source_dir}/second"
    "${_package_dir}"
)

file(WRITE "${_source_dir}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyResolveSiblings LANGUAGES NONE)
include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")
add_subdirectory(first)
add_subdirectory(second)
]=])
foreach(_subdirectory IN ITEMS first second)
    file(WRITE "${_source_dir}/${_subdirectory}/CMakeLists.txt" [=[
canon_resolve_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS DependencyFixture::Core
)
]=])
endforeach()

file(WRITE "${_package_dir}/DependencyFixtureConfig.cmake" [=[
add_library(DependencyFixture::Core INTERFACE IMPORTED)
]=])
write_basic_package_version_file(
    "${_package_dir}/DependencyFixtureConfigVersion.cmake"
    VERSION 7.6.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DDependencyFixture_DIR=${_package_dir}"
)
canon_test_run(
    DESCRIPTION "Installed dependency sibling visibility configure"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - already resolved using installed provider"
    COMMAND ${_configure_command}
)
