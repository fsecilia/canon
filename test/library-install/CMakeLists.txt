# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryInstall LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

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
canon_apply_library(sample_static)

add_library(sample_shared SHARED sample_shared.cpp)
set_target_properties(
    sample_shared
    PROPERTIES
        EXPORT_NAME SharedPublic
        CANON_EXPORT_IDENTITY IPV6_ADDRESS
)
canon_apply_library(sample_shared)

add_library(sample_module MODULE sample.cpp)
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

foreach(_library IN ITEMS sample_interface sample_interface_empty)
    get_target_property(_interface_features "${_library}" INTERFACE_COMPILE_FEATURES)
    if (NOT "cxx_std_26" IN_LIST _interface_features)
        message(FATAL_ERROR "${_library} does not publish Canon's C++26 requirement")
    endif()
endforeach()

foreach(_library IN ITEMS sample_static sample_shared sample_module)
    get_target_property(_features "${_library}" INTERFACE_COMPILE_FEATURES)
    if (NOT "cxx_std_26" IN_LIST _features)
        message(FATAL_ERROR "${_library} does not publish Canon's C++26 requirement")
    endif()
endforeach()

function(_require_alias ALIAS TARGET)
    if (NOT TARGET "${ALIAS}")
        message(FATAL_ERROR "Canon did not create build-tree alias '${ALIAS}'")
    endif()

    get_target_property(_aliased_target "${ALIAS}" ALIASED_TARGET)
    if (NOT "${_aliased_target}" STREQUAL "${TARGET}")
        message(FATAL_ERROR
            "Canon alias '${ALIAS}' targets '${_aliased_target}', expected '${TARGET}'")
    endif()
endfunction()

_require_alias(CanonLibraryInstall::CanonLibraryInstall sample_static)
_require_alias(CanonLibraryInstall::SharedPublic sample_shared)
_require_alias(CanonLibraryInstall::sample_module sample_module)
_require_alias(CanonLibraryInstall::InterfacePublic sample_interface)
_require_alias(CanonLibraryInstall::sample_interface_empty sample_interface_empty)
