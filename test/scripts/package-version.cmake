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

# Configure once; version files are generated during configuration.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
_canon_configure_package_fixture("${_build_dir}")

set(_header_version
    "${_build_dir}/header-only/canon/package/HeaderOnlyPackageConfigVersion.cmake")
set(_mixed_version
    "${_build_dir}/mixed/canon/package/MixedPackageConfigVersion.cmake")
set(_tool_version
    "${_build_dir}/executable/canon/package/ToolPackageConfigVersion.cmake")

# Pre-1.0 packages preserve minor-version compatibility boundaries.
_canon_check_package_version("${_header_version}" 0.7.1 TRUE)
_canon_check_package_version("${_header_version}" 0.6.9 FALSE)

# Stable packages preserve major-version compatibility boundaries.
_canon_check_package_version("${_mixed_version}" 1.2.0 TRUE)
_canon_check_package_version("${_mixed_version}" 2.0.0 FALSE)

# Header-only packages are architecture-independent; compiled artifacts are not.
_canon_check_package_architecture("${_header_version}" 0.7.1 FALSE)
_canon_check_package_architecture("${_mixed_version}" 1.2.0 TRUE)
_canon_check_package_architecture("${_tool_version}" 0.8.1 TRUE)

# A versionless project does not generate a package version file.
set(_versionless_file
    "${_build_dir}/versionless/canon/package/VersionlessPackageConfigVersion.cmake")
if (EXISTS "${_versionless_file}")
    message(FATAL_ERROR "Versionless package unexpectedly generated '${_versionless_file}'")
endif()
