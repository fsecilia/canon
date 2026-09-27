# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonLibraryObjectError LANGUAGES NONE)

include(../common.cmake)

add_library(sample OBJECT IMPORTED)
canon_apply_library(sample)
