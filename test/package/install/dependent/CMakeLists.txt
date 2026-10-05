# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(DependentPackage VERSION 0.9.4 LANGUAGES CXX)

add_library(NoVersionDependency::dependency INTERFACE IMPORTED)

canon_package_dependency(NoVersionDependency)
canon_package_dependency(VersionedDependency 2.5)
canon_package_dependency(ExactDependency 3.1.0 EXACT)

set(_required_components "Alpha;Beta")
canon_package_dependency(
    ComponentDependency
    CONFIG
    COMPONENTS "${_required_components}"
    OPTIONAL_COMPONENTS Gamma
)

add_library(dependent_api INTERFACE)
_canon_package_fixture_add_headers(dependent_api INTERFACE dependent_package/sample.hpp)
target_link_libraries(dependent_api INTERFACE NoVersionDependency::dependency)
canon_apply_library(dependent_api)

canon_package_dependency(NoVersionDependency)
