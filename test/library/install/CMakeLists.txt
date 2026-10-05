# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryInstall LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonFixtureAssertions.cmake")

add_library(sample_static STATIC sample_static.cpp)
set_target_properties(sample_static PROPERTIES EXPORT_NAME CanonLibraryInstall)
target_sources(
    sample_static
    PUBLIC
        FILE_SET arbitrary_name
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/arbitrary/sample.hpp"
)
canon_generate_export_header(
    sample_static
    canon_library_install/export.hpp
    CANON_LIBRARY_INSTALL_API
)
canon_apply_library(sample_static)

add_library(sample_shared SHARED sample_shared.cpp)
set_target_properties(sample_shared PROPERTIES EXPORT_NAME IPv6Address)
canon_generate_export_header(
    sample_shared
    canon_library_install/ipv6_address/export.hpp
    CANON_LIBRARY_INSTALL_IPV6_ADDRESS_API
)
canon_apply_library(sample_shared)

add_library(sample_module MODULE sample.cpp)
canon_generate_export_header(
    sample_module
    canon_library_install/sample_module/export.hpp
    CANON_LIBRARY_INSTALL_SAMPLE_MODULE_API
)
canon_apply_library(sample_module)

add_library(sample_interface INTERFACE)
set_target_properties(sample_interface PROPERTIES EXPORT_NAME InterfacePublic)
target_sources(
    sample_interface
    INTERFACE
        FILE_SET another_arbitrary_name
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/interface_api/sample.hpp"
)
canon_apply_library(sample_interface)

add_library(sample_interface_empty INTERFACE)
canon_apply_library(sample_interface_empty)

include(GNUInstallDirs)
file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/installed-directories.txt"
    CONTENT "${CMAKE_INSTALL_LIBDIR}\n${CMAKE_INSTALL_INCLUDEDIR}\n"
)

file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/installed-library-names.txt"
    CONTENT
        "$<TARGET_FILE_NAME:sample_static>\n$<TARGET_FILE_NAME:sample_shared>\n$<TARGET_FILE_NAME:sample_module>\n"
)

foreach(_library IN ITEMS
    sample_static
    sample_shared
    sample_module
    sample_interface
    sample_interface_empty
)
    canon_test_require_target_list_value(
        "${_library}"
        INTERFACE_COMPILE_FEATURES
        cxx_std_26
    )
endforeach()

canon_test_require_alias(CanonLibraryInstall::CanonLibraryInstall sample_static)
canon_test_require_alias(CanonLibraryInstall::IPv6Address sample_shared)
canon_test_require_alias(CanonLibraryInstall::sample_module sample_module)
canon_test_require_alias(CanonLibraryInstall::InterfacePublic sample_interface)
canon_test_require_alias(CanonLibraryInstall::sample_interface_empty sample_interface_empty)
