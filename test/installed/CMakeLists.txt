# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonInstalledConsumer LANGUAGES CXX)

foreach(_required_variable CANON_EXPECTED_VERSION CANON_EXPECTED_DIR)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

find_package(Canon "${CANON_EXPECTED_VERSION}" CONFIG REQUIRED)

if (NOT "${Canon_DIR}" STREQUAL "${CANON_EXPECTED_DIR}")
    message(FATAL_ERROR
        "Installed Canon was loaded from '${Canon_DIR}', expected '${CANON_EXPECTED_DIR}'")
endif()
foreach(_command IN ITEMS
    canon_apply_target
    canon_generate_export_header
    canon_resolve_dependency
    canon_install_dependency
)
    if (NOT COMMAND "${_command}")
        message(FATAL_ERROR "Installed Canon did not provide ${_command}()")
    endif()
endforeach()
if (NOT "${Canon_VERSION}" STREQUAL "${CANON_EXPECTED_VERSION}")
    message(FATAL_ERROR
        "Installed Canon reported version '${Canon_VERSION}', expected '${CANON_EXPECTED_VERSION}'")
endif()
if (TARGET GTest::gmock_main OR TARGET GTest::gtest_main)
    message(FATAL_ERROR "Loading Canon eagerly provided GoogleTest targets")
endif()

add_library(installed_sample STATIC sample.cpp)
canon_apply_target(installed_sample)
