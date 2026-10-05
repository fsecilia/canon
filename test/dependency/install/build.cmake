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
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
file(MAKE_DIRECTORY "${_source_dir}")
file(COPY
    "${CANON_SOURCE_DIR}/test/dependency/install/build/project/"
    DESTINATION "${_source_dir}"
)

set(_dependency_dir "${_source_dir}/external/fixture-dependency")
file(MAKE_DIRECTORY "${_dependency_dir}")
file(WRITE "${_dependency_dir}/CMakeLists.txt" [=[
add_library(dependency_fixture_runtime SHARED EXCLUDE_FROM_ALL runtime.cpp)
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
    DESCRIPTION "Vendored dependency-install build configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install default build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install build install"
    COMMAND
        "${CMAKE_COMMAND}" --install "${_build_dir}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_install_prefix}"
)

file(STRINGS "${_build_dir}/install-data.txt" _install_data)
list(GET _install_data 0 _libdir)
list(GET _install_data 1 _runtime_name)
if(WIN32)
    set(_installed_runtime "${_install_prefix}/bin/${_runtime_name}")
else()
    set(_installed_runtime "${_install_prefix}/${_libdir}/${_runtime_name}")
endif()
if(NOT EXISTS "${_installed_runtime}")
    message(FATAL_ERROR
        "canon_install_dependency() did not build and install '${_installed_runtime}'")
endif()
