# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonExecutableMissingError LANGUAGES NONE)

include(../common.cmake)

canon_apply_executable(missing)
