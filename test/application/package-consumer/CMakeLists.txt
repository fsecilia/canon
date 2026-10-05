# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonApplicationPackageConsumer LANGUAGES CXX)

find_package(CanonApplicationFixture CONFIG REQUIRED)

add_executable(application_package_consumer main.cpp)
set_property(TARGET application_package_consumer PROPERTY CXX_SCAN_FOR_MODULES FALSE)
target_link_libraries(
    application_package_consumer
    PRIVATE CanonApplicationFixture::fixture_headers
)
