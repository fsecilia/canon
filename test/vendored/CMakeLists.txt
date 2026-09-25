# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonVendoredConsumer LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

if (DEFINED BUILD_TESTING)
    message(FATAL_ERROR "BUILD_TESTING must begin undefined")
endif()

add_subdirectory("${CANON_SOURCE_DIR}" canon EXCLUDE_FROM_ALL)

# Canon's public module should load without exposing its own development setup.
if (NOT COMMAND canon_apply_target)
    message(FATAL_ERROR "Vendored Canon did not provide canon_apply_target()")
endif()
if (COMMAND _canon_add_script_test)
    message(FATAL_ERROR "Vendored Canon exposed its private integration-test helper")
endif()
if (DEFINED BUILD_TESTING)
    message(FATAL_ERROR "Vendored Canon modified BUILD_TESTING")
endif()

add_library(vendored_sample STATIC sample.cpp)
canon_apply_target(vendored_sample)

install(FILES sample.cpp DESTINATION share/canon-vendored-consumer)
