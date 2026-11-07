# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(fixture_support SHARED support.cpp)
add_library(fixture_runtime SHARED EXCLUDE_FROM_ALL runtime.cpp)
set_target_properties(fixture_runtime PROPERTIES VERSION 7.6.0 SOVERSION 7)
target_link_libraries(fixture_runtime PRIVATE fixture_support)
add_library(fixture_decoy SHARED decoy.cpp)

add_library(DependencyFixture::Runtime ALIAS fixture_runtime)
add_library(DependencyFixture::Support ALIAS fixture_support)

# The vendored project's own install rules must stay out of the parent installation.
install(FILES forbidden.txt DESTINATION forbidden)
