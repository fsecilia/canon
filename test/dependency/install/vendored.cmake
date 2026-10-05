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
    "${CANON_SOURCE_DIR}/test/dependency/install/project/"
    DESTINATION "${_source_dir}"
)

set(_dependency_dir "${_source_dir}/external/fixture-dependency")
file(MAKE_DIRECTORY "${_dependency_dir}")
file(WRITE "${_dependency_dir}/CMakeLists.txt" [=[
add_library(dependency_fixture_support SHARED support.cpp)
add_library(dependency_fixture_runtime SHARED runtime.cpp)
target_link_libraries(dependency_fixture_runtime PRIVATE dependency_fixture_support)
add_library(dependency_fixture_decoy SHARED decoy.cpp)

add_library(DependencyFixture::Runtime ALIAS dependency_fixture_runtime)
add_library(DependencyFixture::Support ALIAS dependency_fixture_support)

install(FILES forbidden.txt DESTINATION forbidden)
]=])
file(WRITE "${_dependency_dir}/runtime.cpp" [=[
int dependencyFixtureSupport();
int dependencyFixtureRuntime() { return dependencyFixtureSupport(); }
]=])
file(WRITE "${_dependency_dir}/support.cpp" "int dependencyFixtureSupport() { return 0; }\n")
file(WRITE "${_dependency_dir}/decoy.cpp" "int dependencyFixtureDecoy() { return 0; }\n")
file(WRITE "${_dependency_dir}/forbidden.txt" "vendored install rule must remain excluded\n")

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install configure"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using vendored 'fixture-dependency'"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "Vendored dependency-install install"
    COMMAND
        "${CMAKE_COMMAND}" --install "${_build_dir}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_install_prefix}"
)

file(STRINGS "${_build_dir}/install-data.txt" _install_data)
list(GET _install_data 0 _bindir)
list(GET _install_data 1 _libdir)
list(GET _install_data 2 _runtime_name)
list(GET _install_data 3 _support_name)
list(GET _install_data 4 _decoy_name)

foreach(_library IN ITEMS "${_runtime_name}" "${_support_name}")
    if (WIN32)
        set(_installed_library "${_install_prefix}/${_bindir}/${_library}")
    else()
        set(_installed_library "${_install_prefix}/${_libdir}/${_library}")
    endif()
    if (NOT EXISTS "${_installed_library}")
        message(FATAL_ERROR
            "canon_install_dependency() did not install '${_installed_library}'")
    endif()
endforeach()

if (WIN32)
    set(_decoy "${_install_prefix}/${_bindir}/${_decoy_name}")
else()
    set(_decoy "${_install_prefix}/${_libdir}/${_decoy_name}")
endif()
if (EXISTS "${_decoy}")
    message(FATAL_ERROR "canon_install_dependency() installed unlisted target '${_decoy}'")
endif()
if (EXISTS "${_install_prefix}/forbidden/forbidden.txt")
    message(FATAL_ERROR "vendored dependency install rules leaked into the parent installation")
endif()
