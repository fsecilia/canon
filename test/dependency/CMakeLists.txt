# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Hosts every dependency case. Each external/ subdirectory is one candidate vendored provider, selected by the
# dependency name that a case passes to canon_resolve_dependency().
cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyFixture LANGUAGES CXX)
include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")
