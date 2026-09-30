# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

include("${CANON_SOURCE_DIR}/test/scripts/package-common.cmake")
include(CMakePackageConfigHelpers)

# Configure, build, and install the package fixture from a clean tree.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
_canon_configure_package_fixture("${_build_dir}")

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT "${_build_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon dependency package fixture build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT "${_install_result}" EQUAL 0)
    message(FATAL_ERROR
        "Canon dependency package fixture install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

# Provide the external package that the installed package must recover for its consumer.
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

# Exact duplicate declarations collapse while distinct evaluated argument values remain ordered.
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

string(FIND "${_config}" "include(\"\${CMAKE_CURRENT_LIST_DIR}/DependentPackageTargets.cmake\")" _targets_position)
if (NOT "${_previous_position}" LESS "${_targets_position}")
    message(FATAL_ERROR "DependentPackageConfig.cmake did not recover dependencies before importing targets")
endif()

# The installed target refers to the external target, so consumption proves dependency recovery works.
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

# Source generation preserves values that exercise bracket delimiters and leading newlines.
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
foreach(_call_name IN ITEMS _backslash_call _delimiter_call _syntax_like_call _leading_newline_call)
    set(_expected_call "${${_call_name}}")
    string(FIND "${_literal_config}" "${_expected_call}" _position)
    if ("${_position}" EQUAL -1)
        message(FATAL_ERROR
            "DependentPackageConfig.cmake did not preserve literal argument '${_expected_call}'")
    endif()
endforeach()
