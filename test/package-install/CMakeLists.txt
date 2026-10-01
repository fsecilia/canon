# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonPackageInstall LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

function(_canon_package_fixture_add_headers TARGET SCOPE HEADER)
    target_sources(
        "${TARGET}"
        "${SCOPE}"
            FILE_SET public_headers
            TYPE HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
            FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/${HEADER}"
    )
endfunction()

add_subdirectory(header-only)
add_subdirectory(dependent)
add_subdirectory(mixed)
add_subdirectory(executable)
add_subdirectory(versionless)
