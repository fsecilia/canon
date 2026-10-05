# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_module_dir "${_source_dir}/cmake")
file(MAKE_DIRECTORY "${_module_dir}")

file(WRITE "${_source_dir}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyResolveModule LANGUAGES NONE)
include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
canon_resolve_dependency(
    vulkan-fixture
    PACKAGE VulkanFixture
    VERSION 7.3
    TARGETS VulkanFixture::Vulkan
)
]=])
file(WRITE "${_module_dir}/FindVulkanFixture.cmake" [=[
if(NOT "${VulkanFixture_FIND_VERSION}" STREQUAL "7.3")
    message(FATAL_ERROR "unexpected VulkanFixture version '${VulkanFixture_FIND_VERSION}'")
endif()
add_library(VulkanFixture::Vulkan INTERFACE IMPORTED)
set(VulkanFixture_FOUND TRUE)
]=])

canon_test_make_configure_command(
    _configure_command
    "${_source_dir}"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
)
canon_test_run(
    DESCRIPTION "Default Find-module dependency configure"
    EXPECTED_OUTPUT "finding dependency 'VulkanFixture' - using installed package 'VulkanFixture'"
    COMMAND ${_configure_command}
)
