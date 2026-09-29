# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(DependentPackage VERSION 0.9.4 LANGUAGES CXX)

add_library(DependencyFixture::dependency INTERFACE IMPORTED)

canon_apply_dependency(DependencyFixture 2.5 CONFIG COMPONENTS Alpha)

add_library(dependent_api INTERFACE)
target_sources(
    dependent_api
    INTERFACE
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/dependent_package/sample.hpp"
)
target_link_libraries(dependent_api INTERFACE DependencyFixture::dependency)
canon_apply_library(dependent_api)

canon_apply_dependency(DependencyFixture 2.5 CONFIG COMPONENTS Alpha)
canon_apply_dependency(DependencyFixture 2.5 CONFIG COMPONENTS Beta)
canon_apply_dependency(DependencyFixture 2.5 CONFIG COMPONENTS [=[${SENTINEL}]=])
