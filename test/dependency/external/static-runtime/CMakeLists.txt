# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(static_runtime STATIC "${PROJECT_SOURCE_DIR}/sample.cpp")
add_library(DependencyFixture::Runtime ALIAS static_runtime)
