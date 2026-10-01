# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_TEST_CASE
)

function(_canon_configure_package_fixture BUILD_DIR)
    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/package-install"
        -B "${BUILD_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCMAKE_INSTALL_LIBDIR=artifact-lib
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    list(APPEND _configure_command ${ARGN})

    canon_test_run(
        DESCRIPTION "Canon package fixture configure"
        COMMAND ${_configure_command}
    )
endfunction()

function(_canon_install_package_fixture BUILD_DIR INSTALL_PREFIX)
    canon_test_run(
        DESCRIPTION "Canon package fixture build"
        COMMAND "${CMAKE_COMMAND}" --build "${BUILD_DIR}"
    )
    canon_test_run(
        DESCRIPTION "Canon package fixture install"
        COMMAND "${CMAKE_COMMAND}" --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"
    )
endfunction()

function(
    _canon_build_package_consumer
    INSTALL_PREFIX
    PACKAGE_DIRECTORY
    NAME
    VERSION
    TARGET
    ABSENT_TARGET
)
    string(MAKE_C_IDENTIFIER "${NAME}_${TARGET}" _consumer_name)
    set(_build_dir "${CANON_TEST_BINARY_DIR}/consumer-${_consumer_name}")

    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/package-consumer"
        -B "${_build_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_PACKAGE_NAME=${NAME}"
        "-DCANON_PACKAGE_TARGET=${TARGET}"
        "-D${NAME}_DIR=${INSTALL_PREFIX}/${PACKAGE_DIRECTORY}/${NAME}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
    )
    if (NOT "${VERSION}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_PACKAGE_VERSION=${VERSION}")
    endif()
    if (NOT "${ABSENT_TARGET}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_ABSENT_TARGET=${ABSENT_TARGET}")
    endif()
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    list(APPEND _configure_command ${ARGN})

    canon_test_run(
        DESCRIPTION "Consumer for ${NAME} configure"
        COMMAND ${_configure_command}
    )
    canon_test_run(
        DESCRIPTION "Consumer for ${NAME} build"
        COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
    )
endfunction()

function(_canon_check_package_version VERSION_FILE REQUEST EXPECT_COMPATIBLE)
    set(PACKAGE_FIND_VERSION "${REQUEST}")
    string(REPLACE "." ";" _version_parts "${REQUEST}")
    list(GET _version_parts 0 PACKAGE_FIND_VERSION_MAJOR)
    list(GET _version_parts 1 PACKAGE_FIND_VERSION_MINOR)
    set(PACKAGE_FIND_VERSION_RANGE "")
    unset(PACKAGE_VERSION_COMPATIBLE)
    unset(PACKAGE_VERSION_UNSUITABLE)

    include("${VERSION_FILE}")

    if (EXPECT_COMPATIBLE AND NOT PACKAGE_VERSION_COMPATIBLE)
        message(FATAL_ERROR "${VERSION_FILE} rejected compatible version '${REQUEST}'")
    endif()
    if (NOT EXPECT_COMPATIBLE AND PACKAGE_VERSION_COMPATIBLE)
        message(FATAL_ERROR "${VERSION_FILE} accepted incompatible version '${REQUEST}'")
    endif()
endfunction()

function(_canon_check_package_architecture VERSION_FILE REQUEST EXPECT_UNSUITABLE)
    set(PACKAGE_FIND_VERSION "${REQUEST}")
    string(REPLACE "." ";" _version_parts "${REQUEST}")
    list(GET _version_parts 0 PACKAGE_FIND_VERSION_MAJOR)
    list(GET _version_parts 1 PACKAGE_FIND_VERSION_MINOR)
    set(PACKAGE_FIND_VERSION_RANGE "")
    set(CMAKE_SIZEOF_VOID_P 99)
    unset(PACKAGE_VERSION_UNSUITABLE)

    include("${VERSION_FILE}")

    if (EXPECT_UNSUITABLE AND NOT PACKAGE_VERSION_UNSUITABLE)
        message(FATAL_ERROR "${VERSION_FILE} did not enforce architecture compatibility")
    endif()
    if (NOT EXPECT_UNSUITABLE AND PACKAGE_VERSION_UNSUITABLE)
        message(FATAL_ERROR "${VERSION_FILE} unexpectedly enforced architecture compatibility")
    endif()
endfunction()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")

if ("${CANON_TEST_CASE}" STREQUAL "config")
    set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
    _canon_configure_package_fixture("${_build_dir}")
    _canon_install_package_fixture("${_build_dir}" "${_install_prefix}")

    foreach(_package IN ITEMS HeaderOnlyPackage VersionlessPackage)
        set(_package_dir "${_install_prefix}/share/cmake/${_package}")
        foreach(_file IN ITEMS "${_package}Config.cmake" "${_package}Targets.cmake")
            if (NOT EXISTS "${_package_dir}/${_file}")
                message(FATAL_ERROR "Canon package install did not produce '${_package_dir}/${_file}'")
            endif()
        endforeach()
    endforeach()

    foreach(_package IN ITEMS MixedPackage ToolPackage)
        set(_package_dir "${_install_prefix}/artifact-lib/cmake/${_package}")
        foreach(_file IN ITEMS "${_package}Config.cmake" "${_package}Targets.cmake")
            if (NOT EXISTS "${_package_dir}/${_file}")
                message(FATAL_ERROR "Canon package install did not produce '${_package_dir}/${_file}'")
            endif()
        endforeach()
    endforeach()

    set(_header_version_file
        "${_install_prefix}/share/cmake/HeaderOnlyPackage/HeaderOnlyPackageConfigVersion.cmake")
    if (NOT EXISTS "${_header_version_file}")
        message(FATAL_ERROR "Canon package install did not produce '${_header_version_file}'")
    endif()
    foreach(_package IN ITEMS MixedPackage ToolPackage)
        set(_version_file
            "${_install_prefix}/artifact-lib/cmake/${_package}/${_package}ConfigVersion.cmake")
        if (NOT EXISTS "${_version_file}")
            message(FATAL_ERROR "Canon package install did not produce '${_version_file}'")
        endif()
    endforeach()
    set(_versionless_file
        "${_install_prefix}/share/cmake/VersionlessPackage/VersionlessPackageConfigVersion.cmake")
    if (EXISTS "${_versionless_file}")
        message(FATAL_ERROR "Canon package install unexpectedly produced '${_versionless_file}'")
    endif()

    _canon_build_package_consumer(
        "${_install_prefix}"
        share/cmake
        HeaderOnlyPackage
        0.7.1
        HeaderOnlyPackage::header_api
        ""
    )
    _canon_build_package_consumer(
        "${_install_prefix}"
        artifact-lib/cmake
        MixedPackage
        1.2.0
        MixedPackage::mixed_headers
        ""
    )
    _canon_build_package_consumer(
        "${_install_prefix}"
        artifact-lib/cmake
        MixedPackage
        1.2.0
        MixedPackage::mixed_core
        ""
        -DCANON_PACKAGE_SOURCE=mixed_core.cpp
    )
    _canon_build_package_consumer(
        "${_install_prefix}"
        artifact-lib/cmake
        ToolPackage
        0.8.1
        ToolPackage::tool_api
        ToolPackage::sample_tool
    )
    _canon_build_package_consumer(
        "${_install_prefix}"
        share/cmake
        VersionlessPackage
        ""
        VersionlessPackage::versionless_api
        ""
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "version")
    _canon_configure_package_fixture("${_build_dir}")

    set(_header_version
        "${_build_dir}/header-only/canon/package/HeaderOnlyPackageConfigVersion.cmake")
    set(_mixed_version
        "${_build_dir}/mixed/canon/package/MixedPackageConfigVersion.cmake")
    set(_tool_version
        "${_build_dir}/executable/canon/package/ToolPackageConfigVersion.cmake")

    _canon_check_package_version("${_header_version}" 0.7.1 TRUE)
    _canon_check_package_version("${_header_version}" 0.6.9 FALSE)
    _canon_check_package_version("${_mixed_version}" 1.2.0 TRUE)
    _canon_check_package_version("${_mixed_version}" 2.0.0 FALSE)

    _canon_check_package_architecture("${_header_version}" 0.7.1 FALSE)
    _canon_check_package_architecture("${_mixed_version}" 1.2.0 TRUE)
    _canon_check_package_architecture("${_tool_version}" 0.8.1 TRUE)

    set(_versionless_file
        "${_build_dir}/versionless/canon/package/VersionlessPackageConfigVersion.cmake")
    if (EXISTS "${_versionless_file}")
        message(FATAL_ERROR "Versionless package unexpectedly generated '${_versionless_file}'")
    endif()
elseif ("${CANON_TEST_CASE}" STREQUAL "dependencies")
    include(CMakePackageConfigHelpers)

    set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
    _canon_configure_package_fixture("${_build_dir}")
    _canon_install_package_fixture("${_build_dir}" "${_install_prefix}")

    set(_dependency_dir "${_install_prefix}/artifact-lib/cmake/DependencyFixture")
    file(MAKE_DIRECTORY "${_dependency_dir}")
    file(WRITE "${_dependency_dir}/DependencyFixtureConfig.cmake" [=[
if (NOT TARGET DependencyFixture::dependency)
    add_library(DependencyFixture::dependency INTERFACE IMPORTED)
endif()
]=])
    write_basic_package_version_file(
        "${_dependency_dir}/DependencyFixtureConfigVersion.cmake"
        VERSION 2.8.0
        COMPATIBILITY SameMajorVersion
        ARCH_INDEPENDENT
    )

    set(_config_file
        "${_install_prefix}/share/cmake/DependentPackage/DependentPackageConfig.cmake")
    file(READ "${_config_file}" _config)
    string(REGEX MATCHALL "find_dependency\\(" _dependency_calls "${_config}")
    list(LENGTH _dependency_calls _dependency_call_count)
    if (NOT "${_dependency_call_count}" EQUAL 4)
        message(FATAL_ERROR
            "DependentPackageConfig.cmake contains ${_dependency_call_count} find_dependency() calls; expected 4")
    endif()

    set(_alpha_call [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[Alpha]=])]==])
    set(_beta_call [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[Beta]=])]==])
    set(_literal_call [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[${SENTINEL}]=])]==])
    set(_list_valued_call [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[Gamma;Delta]=])]==])
    set(_previous_position -1)
    foreach(_call_name IN ITEMS _alpha_call _beta_call _literal_call _list_valued_call)
        set(_expected_call "${${_call_name}}")
        string(FIND "${_config}" "${_expected_call}" _position)
        if ("${_position}" EQUAL -1 OR NOT "${_previous_position}" LESS "${_position}")
            message(FATAL_ERROR
                "DependentPackageConfig.cmake did not preserve dependency declaration '${_expected_call}'")
        endif()
        set(_previous_position "${_position}")
    endforeach()

    string(FIND
        "${_config}"
        "include(\"\${CMAKE_CURRENT_LIST_DIR}/DependentPackageTargets.cmake\")"
        _targets_position
    )
    if (NOT "${_previous_position}" LESS "${_targets_position}")
        message(FATAL_ERROR
            "DependentPackageConfig.cmake did not recover dependencies before importing targets")
    endif()

    _canon_build_package_consumer(
        "${_install_prefix}"
        share/cmake
        DependentPackage
        0.9.1
        DependentPackage::dependent_api
        ""
        "-DDependencyFixture_DIR=${_dependency_dir}"
        -DSENTINEL=canon-expanded-sentinel
    )

    set(_literal_build_dir "${CANON_TEST_BINARY_DIR}/literal-build")
    _canon_configure_package_fixture(
        "${_literal_build_dir}"
        -DCANON_TEST_DEPENDENCY_LITERAL_ARGUMENTS=ON
    )
    set(_literal_config_file
        "${_literal_build_dir}/dependent/canon/package/DependentPackageConfig.cmake")
    file(READ "${_literal_config_file}" _literal_config)
    set(_backslash_call
        [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[path\segment]=])]==])
    set(_delimiter_call
        [===[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [==[right]]middle]=]edge]==])]===])
    set(_syntax_like_call
        [==[find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[[[${[[mismatched}]]]=])]==])
    set(_leading_newline_call
        "find_dependency([=[DependencyFixture]=] [=[2.5]=] [=[CONFIG]=] [=[COMPONENTS]=] [=[\n\nLeading]=])")
    foreach(_call_name IN ITEMS
        _backslash_call
        _delimiter_call
        _syntax_like_call
        _leading_newline_call
    )
        set(_expected_call "${${_call_name}}")
        string(FIND "${_literal_config}" "${_expected_call}" _position)
        if ("${_position}" EQUAL -1)
            message(FATAL_ERROR
                "DependentPackageConfig.cmake did not preserve literal argument '${_expected_call}'")
        endif()
    endforeach()
else()
    message(FATAL_ERROR "Unknown package test case '${CANON_TEST_CASE}'")
endif()
