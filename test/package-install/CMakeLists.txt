# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonPackageInstall LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

add_subdirectory(header-only)
add_subdirectory(dependent)
add_subdirectory(mixed)
add_subdirectory(executable)
add_subdirectory(versionless)
