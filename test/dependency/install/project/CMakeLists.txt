# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyInstall LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

canon_resolve_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS DependencyFixture::Runtime
)

canon_install_dependency(
    fixture-dependency
    TARGETS
        DependencyFixture::Runtime
        DependencyFixture::Support
)
canon_install_dependency(
    fixture-dependency
    TARGETS DependencyFixture::Runtime
)

add_executable(sample main.cpp)
target_link_libraries(sample PRIVATE DependencyFixture::Runtime)
canon_apply_target(sample)

include(GNUInstallDirs)
install(TARGETS sample RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/install-data.txt"
    CONTENT
        "${CMAKE_INSTALL_BINDIR}\n${CMAKE_INSTALL_LIBDIR}\n$<TARGET_FILE_NAME:dependency_fixture_runtime>\n$<TARGET_FILE_NAME:dependency_fixture_support>\n$<TARGET_FILE_NAME:dependency_fixture_decoy>\n"
)
