# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDependencyNoPackageError LANGUAGES NONE)

include(../common.cmake)

canon_apply_dependency(DependencyFixture CONFIG)
