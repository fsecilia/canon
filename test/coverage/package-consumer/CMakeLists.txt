# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoveragePackageConsumer LANGUAGES CXX)

find_package(CanonCoverageFixture CONFIG REQUIRED)

add_executable(coverage_consumer main.cpp)
set_property(TARGET coverage_consumer PROPERTY CXX_SCAN_FOR_MODULES FALSE)
target_link_libraries(coverage_consumer PRIVATE CanonCoverageFixture::covered)
