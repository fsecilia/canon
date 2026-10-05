# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonLibraryArguments LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../../support/CanonSourceFixture.cmake")

add_library(sample INTERFACE)
canon_apply_library(sample unexpected)
