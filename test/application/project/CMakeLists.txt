# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonApplicationFixture VERSION 0.1.0 LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

add_library(fixture_headers INTERFACE)
add_library(CanonApplicationFixture::fixture_headers ALIAS fixture_headers)
target_sources(
    fixture_headers
    INTERFACE
        FILE_SET HEADERS
        BASE_DIRS include
        FILES include/canon_application_fixture/fixture_headers.hpp
)
canon_apply_library(fixture_headers)

canon_resolve_dependency(
    runtime
    PACKAGE FixtureRuntime
    VERSION "3.2...<4.0"
    TARGETS FixtureRuntime::Runtime
)
canon_resolve_dependency(
    graphics
    PACKAGE FixtureGraphics
    VERSION "1.3...<2.0"
    TARGETS FixtureGraphics::Graphics
)

add_library(engine SHARED engine.cpp)
canon_apply_target(engine)
canon_generate_export_header(
    engine
    canon_application_fixture/engine_export.hpp
    CANON_APPLICATION_ENGINE_API
)
target_link_libraries(
    engine
    PRIVATE
        fixture_headers
        FixtureRuntime::Runtime
        FixtureGraphics::Graphics
)

add_executable(game game.cpp)
target_link_libraries(game PRIVATE engine fixture_headers)
canon_apply_target(game)

canon_install_dependency(runtime TARGETS FixtureRuntime::Runtime)

install(
    TARGETS fixture_headers
    EXPORT CanonApplicationFixtureTargets
    FILE_SET HEADERS DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)
install(
    TARGETS engine game
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
install(
    EXPORT CanonApplicationFixtureTargets
    FILE CanonApplicationFixtureTargets.cmake
    NAMESPACE CanonApplicationFixture::
    DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/CanonApplicationFixture"
)

configure_package_config_file(
    cmake/CanonApplicationFixtureConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/CanonApplicationFixtureConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/CanonApplicationFixture"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CanonApplicationFixtureConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMinorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/CanonApplicationFixtureConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/CanonApplicationFixtureConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/CanonApplicationFixture"
)

file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/install-data.txt"
    CONTENT
        "${CMAKE_INSTALL_BINDIR}\n${CMAKE_INSTALL_LIBDIR}\n${CMAKE_INSTALL_DATADIR}\n$<TARGET_FILE_NAME:engine>\n$<TARGET_FILE_NAME:fixture_runtime_shared>\n"
)
