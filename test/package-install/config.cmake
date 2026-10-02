# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/package-install/common.cmake")

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")

set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
_canon_configure_package_fixture("${_build_dir}")
_canon_install_package_fixture("${_build_dir}" "${_install_prefix}")

foreach(_package IN ITEMS HeaderOnlyPackage VersionlessPackage)
    set(_package_dir "${_install_prefix}/artifact-data/cmake/${_package}")
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
    "${_install_prefix}/artifact-data/cmake/HeaderOnlyPackage/HeaderOnlyPackageConfigVersion.cmake")
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
    "${_install_prefix}/artifact-data/cmake/VersionlessPackage/VersionlessPackageConfigVersion.cmake")
if (EXISTS "${_versionless_file}")
    message(FATAL_ERROR "Canon package install unexpectedly produced '${_versionless_file}'")
endif()

_canon_build_package_consumer(
    "${_install_prefix}"
    artifact-data/cmake
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
    artifact-data/cmake
    VersionlessPackage
    ""
    VersionlessPackage::versionless_api
    ""
)
