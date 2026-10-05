# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/dependency/resolve/common.cmake")
include(CMakePackageConfigHelpers)

_canon_prepare_required_dependency_fixture(_source_dir _build_dir)
set(_package_dir "${CANON_TEST_BINARY_DIR}/package/DependencyFixture")
file(MAKE_DIRECTORY "${_package_dir}")
file(WRITE "${_package_dir}/DependencyFixtureConfig.cmake" [=[
if(NOT "${DependencyFixture_FIND_VERSION_RANGE}" STREQUAL "7.3...<8.0")
    message(FATAL_ERROR
        "DependencyFixture received version range '${DependencyFixture_FIND_VERSION_RANGE}'")
endif()
add_library(DependencyFixture::Core INTERFACE IMPORTED)
add_library(DependencyFixture::Support INTERFACE IMPORTED)
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
    DESCRIPTION "Installed required dependency configure"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using installed package 'DependencyFixture'"
    COMMAND ${_configure_command}
)
