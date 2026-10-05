# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/package/install/common.cmake")

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
file(MAKE_DIRECTORY "${_source_dir}")
file(COPY
    "${CANON_SOURCE_DIR}/test/dependency/install/architecture/project/"
    DESTINATION "${_source_dir}"
)

set(_dependency_dir "${_source_dir}/external/fixture-dependency")
file(MAKE_DIRECTORY "${_dependency_dir}")
file(WRITE "${_dependency_dir}/CMakeLists.txt" [=[
add_library(dependency_fixture_runtime SHARED runtime.cpp)
add_library(DependencyFixture::Runtime ALIAS dependency_fixture_runtime)
]=])
file(WRITE "${_dependency_dir}/runtime.cpp" "int dependencyFixtureRuntime() { return 0; }\n")

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install architecture configure"
    COMMAND ${_configure_command}
)

set(_version_file
    "${_build_dir}/canon/package/ArchitectureFixtureConfigVersion.cmake")
_canon_check_package_architecture("${_version_file}" 0.7.3 TRUE)
