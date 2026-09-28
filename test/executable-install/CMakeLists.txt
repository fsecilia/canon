# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableInstall LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_executable(sample main.cpp)
canon_apply_executable(sample)

file(
    GENERATE
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/installed-executable-name.txt"
    CONTENT "$<TARGET_FILE_NAME:sample>\n"
)
