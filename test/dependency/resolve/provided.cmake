# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/dependency/resolve/common.cmake")

_canon_prepare_required_dependency_fixture(_source_dir _build_dir)
set(_dependency_dir "${_source_dir}/external/fixture-dependency")
file(MAKE_DIRECTORY "${_dependency_dir}")
file(WRITE "${_dependency_dir}/CMakeLists.txt" [=[
message(FATAL_ERROR "Preprovided dependency unexpectedly loaded the vendored project")
]=])

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCANON_PROVIDE_CORE=ON
    -DCANON_PROVIDE_SUPPORT=ON
)
canon_test_run(
    DESCRIPTION "Preprovided required dependency configure"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - already provided"
    COMMAND ${_configure_command}
)
