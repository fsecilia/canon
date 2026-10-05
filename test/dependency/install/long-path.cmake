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

string(LENGTH "${CANON_TEST_BINARY_DIR}" _test_binary_dir_length)
math(EXPR _padding_length "160 - ${_test_binary_dir_length}")
if(_padding_length LESS 16)
    set(_padding_length 16)
endif()
string(REPEAT x ${_padding_length} _padding)
set(_build_dir "${CANON_TEST_BINARY_DIR}/${_padding}/build")

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
    DESCRIPTION "Vendored dependency-install long-path configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install long-path build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)