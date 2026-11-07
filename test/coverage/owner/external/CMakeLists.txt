# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(CanonCoverageOwned LANGUAGES CXX)

add_library(owned STATIC owned.cpp external/owned_vendor.cpp)
canon_apply_library(owned)
