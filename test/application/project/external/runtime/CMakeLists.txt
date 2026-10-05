# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(fixture_runtime_shared SHARED runtime.cpp)
add_library(FixtureRuntime::Runtime ALIAS fixture_runtime_shared)
