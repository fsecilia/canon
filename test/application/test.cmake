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
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/application/project"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
    -DCMAKE_INSTALL_LIBDIR=artifact-lib
    -DCMAKE_INSTALL_DATADIR=artifact-share
)
canon_test_run(
    DESCRIPTION "Application-shaped fixture configure"
    EXPECTED_OUTPUT
        "finding dependency 'FixtureRuntime' - using vendored 'runtime'"
        "finding dependency 'FixtureGraphics' - using installed package 'FixtureGraphics'"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Application-shaped fixture build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --config "${CANON_TEST_CONFIG}"
)

canon_test_executable_path(_game "${_build_dir}" game)
canon_test_run(
    DESCRIPTION "Application-shaped build-tree executable"
    COMMAND "${_game}"
)

canon_test_run(
    DESCRIPTION "Application-shaped fixture install"
    COMMAND
        "${CMAKE_COMMAND}" --install "${_build_dir}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_install_prefix}"
)

file(STRINGS "${_build_dir}/install-data.txt" _install_data)
list(GET _install_data 0 _bindir)
list(GET _install_data 1 _libdir)
list(GET _install_data 2 _datadir)
list(GET _install_data 3 _engine_name)
list(GET _install_data 4 _vendored_runtime_name)

foreach(_runtime_name IN ITEMS "${_engine_name}" "${_vendored_runtime_name}")
    if (WIN32)
        set(_installed_runtime "${_install_prefix}/${_bindir}/${_runtime_name}")
    else()
        set(_installed_runtime "${_install_prefix}/${_libdir}/${_runtime_name}")
    endif()
    if (NOT EXISTS "${_installed_runtime}")
        message(FATAL_ERROR
            "Application-shaped install is missing '${_installed_runtime}'")
    endif()
endforeach()

set(_package_dir "${_install_prefix}/${_datadir}/cmake/CanonApplicationFixture")
foreach(_package_file IN ITEMS
    CanonApplicationFixtureConfig.cmake
    CanonApplicationFixtureConfigVersion.cmake
    CanonApplicationFixtureTargets.cmake
)
    if (NOT EXISTS "${_package_dir}/${_package_file}")
        message(FATAL_ERROR
            "Application-shaped install is missing '${_package_dir}/${_package_file}'")
    endif()
endforeach()

set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
canon_test_make_configure_command(
    _consumer_configure_command
    "${CANON_SOURCE_DIR}/test/application/package-consumer"
    "${_consumer_build_dir}"
    "-DCanonApplicationFixture_DIR=${_package_dir}"
    -DCMAKE_BUILD_TYPE=Debug
)
canon_test_run(
    DESCRIPTION "Application-shaped package consumer configure"
    COMMAND ${_consumer_configure_command}
)
canon_test_run(
    DESCRIPTION "Application-shaped package consumer build"
    COMMAND
        "${CMAKE_COMMAND}" --build "${_consumer_build_dir}"
        --config "${CANON_TEST_CONFIG}"
)
canon_test_executable_path(
    _consumer
    "${_consumer_build_dir}"
    application_package_consumer
)
canon_test_run(
    DESCRIPTION "Application-shaped package consumer"
    COMMAND "${_consumer}"
)
