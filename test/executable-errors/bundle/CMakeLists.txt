# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableBundleError LANGUAGES NONE)

include(../common.cmake)

add_executable(sample IMPORTED)
set_property(TARGET sample PROPERTY MACOSX_BUNDLE TRUE)
canon_apply_executable(sample)
