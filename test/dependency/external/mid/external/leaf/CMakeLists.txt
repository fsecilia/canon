# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(LeafFixture LANGUAGES CXX)
add_library(leaf_runtime SHARED runtime.cpp)
add_library(LeafFixture::Runtime ALIAS leaf_runtime)
