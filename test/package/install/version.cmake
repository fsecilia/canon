# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/package/install/common.cmake")

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")

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
