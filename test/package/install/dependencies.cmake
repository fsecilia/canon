# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/package/install/common.cmake")

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")

include(CMakePackageConfigHelpers)

set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
_canon_configure_package_fixture("${_build_dir}")
_canon_install_package_fixture("${_build_dir}" "${_install_prefix}")

set(_dependency_root "${CANON_TEST_BINARY_DIR}/dependencies")

set(_no_version_dir "${_dependency_root}/NoVersionDependency")
file(MAKE_DIRECTORY "${_no_version_dir}")
file(WRITE "${_no_version_dir}/NoVersionDependencyConfig.cmake" [=[
if (NOT "${NoVersionDependency_FIND_VERSION}" STREQUAL "")
    message(FATAL_ERROR
        "NoVersionDependency received unexpected version '${NoVersionDependency_FIND_VERSION}'")
endif()
if (NOT "${NoVersionDependency_FIND_COMPONENTS}" STREQUAL "")
    message(FATAL_ERROR
        "NoVersionDependency received unexpected components '${NoVersionDependency_FIND_COMPONENTS}'")
endif()
if (NOT TARGET NoVersionDependency::dependency)
    add_library(NoVersionDependency::dependency INTERFACE IMPORTED)
endif()
]=])

set(_versioned_dir "${_dependency_root}/VersionedDependency")
file(MAKE_DIRECTORY "${_versioned_dir}")
file(WRITE "${_versioned_dir}/VersionedDependencyConfig.cmake" [=[
if (NOT "${VersionedDependency_FIND_VERSION}" STREQUAL "2.5")
    message(FATAL_ERROR
        "VersionedDependency received version '${VersionedDependency_FIND_VERSION}'; expected '2.5'")
endif()
if (VersionedDependency_FIND_VERSION_EXACT)
    message(FATAL_ERROR "VersionedDependency unexpectedly received an EXACT request")
endif()
]=])
write_basic_package_version_file(
    "${_versioned_dir}/VersionedDependencyConfigVersion.cmake"
    VERSION 2.8.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

set(_exact_dir "${_dependency_root}/ExactDependency")
file(MAKE_DIRECTORY "${_exact_dir}")
file(WRITE "${_exact_dir}/ExactDependencyConfig.cmake" [=[
if (NOT "${ExactDependency_FIND_VERSION}" STREQUAL "3.1.0")
    message(FATAL_ERROR
        "ExactDependency received version '${ExactDependency_FIND_VERSION}'; expected '3.1.0'")
endif()
if (NOT ExactDependency_FIND_VERSION_EXACT)
    message(FATAL_ERROR "ExactDependency did not receive an EXACT request")
endif()
]=])
write_basic_package_version_file(
    "${_exact_dir}/ExactDependencyConfigVersion.cmake"
    VERSION 3.1.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

set(_component_dir "${_dependency_root}/ComponentDependency")
file(MAKE_DIRECTORY "${_component_dir}")
file(WRITE "${_component_dir}/ComponentDependencyConfig.cmake" [=[
if (NOT "${ComponentDependency_FIND_COMPONENTS}" STREQUAL "Alpha;Beta;Gamma")
    message(FATAL_ERROR
        "ComponentDependency received components '${ComponentDependency_FIND_COMPONENTS}'; expected 'Alpha;Beta;Gamma'")
endif()
foreach(_required_component IN ITEMS Alpha Beta)
    if (NOT ComponentDependency_FIND_REQUIRED_${_required_component})
        message(FATAL_ERROR
            "ComponentDependency component '${_required_component}' was not required")
    endif()
endforeach()
if (ComponentDependency_FIND_REQUIRED_Gamma)
    message(FATAL_ERROR "ComponentDependency optional component 'Gamma' was required")
endif()
]=])

set(_module_dir "${_dependency_root}/modules")
file(MAKE_DIRECTORY "${_module_dir}")
file(WRITE "${_module_dir}/FindComponentDependency.cmake" [=[
message(FATAL_ERROR
    "ComponentDependency was searched in module mode; canon_propagate_dependency() did not forward CONFIG")
]=])

set(_config_file
    "${_install_prefix}/artifact-data/cmake/DependentPackage/DependentPackageConfig.cmake")
file(READ "${_config_file}" _config)
string(REGEX MATCHALL "find_dependency\\(" _dependency_calls "${_config}")
list(LENGTH _dependency_calls _dependency_call_count)
if (NOT "${_dependency_call_count}" EQUAL 4)
    message(FATAL_ERROR
        "DependentPackageConfig.cmake contains ${_dependency_call_count} find_dependency() calls; expected 4")
endif()

string(FIND "${_config}" "find_dependency(" _dependency_position)
string(FIND
    "${_config}"
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/DependentPackageTargets.cmake\")"
    _targets_position
)
if ("${_dependency_position}" EQUAL -1
    OR NOT "${_dependency_position}" LESS "${_targets_position}")
    message(FATAL_ERROR
        "DependentPackageConfig.cmake did not recover dependencies before importing targets")
endif()

_canon_build_package_consumer(
    "${_install_prefix}"
    artifact-data/cmake
    DependentPackage
    0.9.1
    DependentPackage::dependent_api
    ""
    "-DNoVersionDependency_DIR=${_no_version_dir}"
    "-DVersionedDependency_DIR=${_versioned_dir}"
    "-DExactDependency_DIR=${_exact_dir}"
    "-DComponentDependency_DIR=${_component_dir}"
    "-DCMAKE_MODULE_PATH=${_module_dir}"
)
