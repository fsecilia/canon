# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableLibraryError LANGUAGES NONE)

include(../common.cmake)

add_library(sample INTERFACE)
canon_apply_executable(sample)
