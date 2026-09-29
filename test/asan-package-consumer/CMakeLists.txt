# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonAsanPackageConsumer LANGUAGES CXX)

find_package(CanonAsanFixture CONFIG REQUIRED)

add_executable(asan_static_consumer static.cpp)
set_property(TARGET asan_static_consumer PROPERTY CXX_SCAN_FOR_MODULES FALSE)
target_link_libraries(asan_static_consumer PRIVATE CanonAsanFixture::asan_static)

add_executable(asan_shared_consumer shared.cpp)
set_property(TARGET asan_shared_consumer PROPERTY CXX_SCAN_FOR_MODULES FALSE)
target_link_libraries(asan_shared_consumer PRIVATE CanonAsanFixture::asan_shared)
