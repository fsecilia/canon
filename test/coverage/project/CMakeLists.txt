# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageFixture LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (NOT CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "coverage fixture requires CANON_ENABLE_COVERAGE=ON")
endif()

include(CTest)
include("${CANON_SOURCE_DIR}/test/support/CanonFixtureAssertions.cmake")

add_library(covered STATIC covered.cpp external/excluded.cpp)
add_library(covered_object OBJECT covered.cpp)
canon_apply_library(covered)
canon_apply_target(covered_object)

if (NOT TARGET coverage-clean OR NOT TARGET coverage-report)
    message(FATAL_ERROR "coverage helpers were not created for the coverage build")
endif()

add_executable(covered_test covered_test.cpp)
target_link_libraries(covered_test PRIVATE covered)
canon_apply_target(covered_test)
add_test(NAME covered_test COMMAND covered_test)

add_executable(covered_unmanaged covered_test.cpp)
target_link_libraries(covered_unmanaged PRIVATE covered)
set_property(TARGET covered_unmanaged PROPERTY CXX_SCAN_FOR_MODULES FALSE)
add_test(NAME covered_unmanaged COMMAND covered_unmanaged)

add_executable(covered_object_unmanaged covered_object_test.cpp)
target_link_libraries(covered_object_unmanaged PRIVATE covered_object)
set_property(TARGET covered_object_unmanaged PROPERTY CXX_SCAN_FOR_MODULES FALSE)
add_test(NAME covered_object_unmanaged COMMAND covered_object_unmanaged)

# Verify compile instrumentation on every managed target in the fixture.
foreach(_target IN ITEMS covered covered_object covered_test)
    canon_test_require_cxx_compile_option("${_target}" "--coverage")
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        canon_test_require_cxx_compile_option("${_target}" "-fprofile-abs-path")
    endif()
endforeach()

# Static- and object-library consumers must inherit the coverage runtime without compile instrumentation.
canon_test_require_target_list_value(covered INTERFACE_LINK_OPTIONS --coverage)
canon_test_require_target_list_value(covered_object INTERFACE_LINK_OPTIONS --coverage)
canon_test_require_target_list_value(covered_test LINK_OPTIONS --coverage)
canon_test_forbid_target_list_value(covered_unmanaged COMPILE_OPTIONS --coverage)
canon_test_forbid_target_list_value(covered_object_unmanaged COMPILE_OPTIONS --coverage)
