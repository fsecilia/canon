# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyQuietError LANGUAGES NONE)

include(../common.cmake)

canon_apply_dependency(DependencyFixture QUIET)
