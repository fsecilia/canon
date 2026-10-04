# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableIdempotence LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

add_executable(sample "${CMAKE_CURRENT_LIST_DIR}/../../support/empty_main.cpp")
canon_apply_target(sample)
canon_apply_executable(sample)
canon_apply_executable(sample)
