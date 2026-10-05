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
set(_mid_dir "${_source_dir}/external/mid")
set(_leaf_dir "${_mid_dir}/external/leaf")
file(MAKE_DIRECTORY "${_leaf_dir}")

file(WRITE "${_source_dir}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyInstallNested LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

canon_resolve_dependency(
    mid
    PACKAGE MidFixture
    VERSION "7.3...<8.0"
    TARGETS MidFixture::Core
)
canon_resolve_dependency(
    leaf
    PACKAGE LeafFixture
    VERSION "7.3...<8.0"
    TARGETS LeafFixture::Runtime
)
canon_install_dependency(
    leaf
    TARGETS LeafFixture::Runtime
)

include(GNUInstallDirs)
file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/install-data.txt"
    CONTENT "${CMAKE_INSTALL_LIBDIR}\n$<TARGET_FILE_NAME:leaf_fixture_runtime>\n"
)
]=])

file(WRITE "${_mid_dir}/CMakeLists.txt" [=[
project(MidFixture LANGUAGES CXX)

canon_resolve_dependency(
    leaf
    PACKAGE LeafFixture
    VERSION "7.3...<8.0"
    TARGETS LeafFixture::Runtime
)

add_library(mid_fixture_core INTERFACE)
add_library(MidFixture::Core ALIAS mid_fixture_core)
]=])

file(WRITE "${_leaf_dir}/CMakeLists.txt" [=[
project(LeafFixture LANGUAGES CXX)

add_library(leaf_fixture_runtime SHARED runtime.cpp)
add_library(LeafFixture::Runtime ALIAS leaf_fixture_runtime)
]=])
file(WRITE "${_leaf_dir}/runtime.cpp" "int leafFixtureRuntime() { return 0; }\n")

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)
canon_test_run(
    DESCRIPTION "Nested dependency provider configure"
    EXPECTED_OUTPUT
        "finding dependency 'LeafFixture' - using vendored 'leaf'"
        "finding dependency 'LeafFixture' - already resolved using vendored provider"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Nested dependency provider build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "Nested dependency provider install"
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
        "nested dependency provider provenance did not install '${_installed_runtime}'")
endif()
