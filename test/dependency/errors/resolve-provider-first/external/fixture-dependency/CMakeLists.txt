# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(dependency_fixture_support INTERFACE)
add_library(DependencyFixture::Support ALIAS dependency_fixture_support)
