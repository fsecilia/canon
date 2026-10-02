# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonPackageConsumer LANGUAGES CXX)

foreach(_required_variable CANON_PACKAGE_NAME CANON_PACKAGE_TARGET)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

if (DEFINED CANON_PACKAGE_VERSION AND NOT "${CANON_PACKAGE_VERSION}" STREQUAL "")
    find_package("${CANON_PACKAGE_NAME}" "${CANON_PACKAGE_VERSION}" CONFIG REQUIRED)
else()
    find_package("${CANON_PACKAGE_NAME}" CONFIG REQUIRED)
endif()

if (NOT TARGET "${CANON_PACKAGE_TARGET}")
    message(FATAL_ERROR "Package did not provide target '${CANON_PACKAGE_TARGET}'")
endif()
if (DEFINED CANON_ABSENT_TARGET
    AND NOT "${CANON_ABSENT_TARGET}" STREQUAL ""
    AND TARGET "${CANON_ABSENT_TARGET}")
    message(FATAL_ERROR "Package unexpectedly exported target '${CANON_ABSENT_TARGET}'")
endif()

if (DEFINED CANON_PACKAGE_SOURCE AND NOT "${CANON_PACKAGE_SOURCE}" STREQUAL "")
    add_executable(package_consumer "${CANON_PACKAGE_SOURCE}")
else()
    add_executable(package_consumer "${CMAKE_CURRENT_LIST_DIR}/../../support/empty_main.cpp")
endif()
set_property(TARGET package_consumer PROPERTY CXX_SCAN_FOR_MODULES FALSE)
target_link_libraries(package_consumer PRIVATE "${CANON_PACKAGE_TARGET}")
