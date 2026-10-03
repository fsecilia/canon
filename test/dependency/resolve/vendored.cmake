# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/dependency/resolve/common.cmake")

_canon_prepare_required_dependency_fixture(_source_dir _build_dir)
set(_dependency_dir "${_source_dir}/external/fixture-dependency")
file(MAKE_DIRECTORY "${_dependency_dir}")
file(WRITE "${_dependency_dir}/CMakeLists.txt" [=[
add_library(dependency_fixture_core INTERFACE)
add_library(dependency_fixture_support INTERFACE)
add_library(DependencyFixture::Core ALIAS dependency_fixture_core)
add_library(DependencyFixture::Support ALIAS dependency_fixture_support)
]=])

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)
canon_test_run(
    DESCRIPTION "Vendored required dependency configure"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using vendored 'fixture-dependency'"
    COMMAND ${_configure_command}
)
