# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryIdempotence VERSION 1.0.0 LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

add_library(sample STATIC "${CMAKE_CURRENT_LIST_DIR}/../../support/empty_main.cpp")
canon_apply_target(sample)
canon_generate_export_header(sample sample/export.hpp SAMPLE_API)
canon_apply_library(sample)
canon_apply_library(sample)
