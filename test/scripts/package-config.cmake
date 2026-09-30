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

# Configure, build, and install all package shapes from a clean tree.
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
        "Canon package fixture build failed\n"
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
        "Canon package fixture install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

# Require architecture-independent package metadata below share/cmake.
foreach(_package IN ITEMS HeaderOnlyPackage VersionlessPackage)
    set(_package_dir "${_install_prefix}/share/cmake/${_package}")
    foreach(_file IN ITEMS "${_package}Config.cmake" "${_package}Targets.cmake")
        if (NOT EXISTS "${_package_dir}/${_file}")
            message(FATAL_ERROR "Canon package install did not produce '${_package_dir}/${_file}'")
        endif()
    endforeach()
endforeach()

# Require architecture-specific package metadata below the configured library directory.
foreach(_package IN ITEMS MixedPackage ToolPackage)
    set(_package_dir "${_install_prefix}/artifact-lib/cmake/${_package}")
    foreach(_file IN ITEMS "${_package}Config.cmake" "${_package}Targets.cmake")
        if (NOT EXISTS "${_package_dir}/${_file}")
            message(FATAL_ERROR "Canon package install did not produce '${_package_dir}/${_file}'")
        endif()
    endforeach()
endforeach()

# Versioned projects install a version file; versionless projects do not invent one.
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

# Consume each package through find_package() and its exported namespaced targets.
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
