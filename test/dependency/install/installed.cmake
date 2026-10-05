# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/dependency/resolve/common.cmake")
include(CMakePackageConfigHelpers)

_canon_prepare_required_dependency_fixture(_source_dir _build_dir)
set(_package_dir "${CANON_TEST_BINARY_DIR}/package/DependencyFixture")
file(MAKE_DIRECTORY "${_package_dir}")
file(WRITE "${_package_dir}/DependencyFixtureConfig.cmake" [=[
add_library(DependencyFixture::Core INTERFACE IMPORTED)
add_library(DependencyFixture::Support INTERFACE IMPORTED)
]=])
write_basic_package_version_file(
    "${_package_dir}/DependencyFixtureConfigVersion.cmake"
    VERSION 7.6.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

_canon_configure_required_dependency_fixture(
    "${_source_dir}"
    "${_build_dir}"
    "Installed dependency runtime-install no-op"
    "-DDependencyFixture_DIR=${_package_dir}"
    -DCANON_INSTALL_DEPENDENCY=ON
)
