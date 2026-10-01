# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonAsanFixture LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if (NOT CANON_ENABLE_ASAN)
    message(FATAL_ERROR "ASan fixture requires CANON_ENABLE_ASAN=ON")
endif()

include(CTest)
include("${CANON_SOURCE_DIR}/test/support/CanonFixtureAssertions.cmake")

add_library(asan_static STATIC asan_static.cpp)
add_library(asan_shared SHARED asan_shared.cpp)
add_library(unmanaged STATIC unmanaged.cpp)
canon_apply_library(asan_static)
canon_apply_library(asan_shared)

add_executable(asan_app main.cpp)
target_link_libraries(asan_app PRIVATE asan_static asan_shared unmanaged)
canon_apply_target(asan_app)

add_executable(asan_test asan_test.cpp)
target_link_libraries(asan_test PRIVATE asan_static)
canon_apply_target(asan_test)
add_test(NAME asan_test COMMAND asan_test)

add_executable(asan_unmanaged_static asan_test.cpp)
target_link_libraries(asan_unmanaged_static PRIVATE asan_static)
set_property(TARGET asan_unmanaged_static PROPERTY CXX_SCAN_FOR_MODULES FALSE)
add_test(NAME asan_unmanaged_static COMMAND asan_unmanaged_static)

add_executable(asan_unmanaged_shared asan_shared_test.cpp)
target_link_libraries(asan_unmanaged_shared PRIVATE asan_shared)
set_property(TARGET asan_unmanaged_shared PROPERTY CXX_SCAN_FOR_MODULES FALSE)
add_test(NAME asan_unmanaged_shared COMMAND asan_unmanaged_shared)

add_executable(asan_probe EXCLUDE_FROM_ALL asan_probe.cpp)
canon_apply_target(asan_probe)

# Verify the compile policy reaches each managed target involved in the fixture.
foreach(_target IN ITEMS asan_static asan_shared asan_app asan_test asan_probe)
    canon_test_require_cxx_compile_option("${_target}" -fsanitize=address)
    canon_test_require_cxx_compile_option("${_target}" -fno-omit-frame-pointer)
endforeach()

# Verify each managed target publishes the sanitizer runtime where its consumers need it.
canon_test_require_target_list_value(asan_static INTERFACE_LINK_OPTIONS -fsanitize=address)
canon_test_require_target_list_value(asan_shared LINK_OPTIONS -fsanitize=address)
canon_test_require_target_list_value(asan_shared INTERFACE_LINK_OPTIONS -fsanitize=address)

foreach(_target IN ITEMS asan_app asan_test asan_probe)
    canon_test_require_target_list_value("${_target}" LINK_OPTIONS -fsanitize=address)
endforeach()

# Keep unmanaged target state untouched by Canon's sanitizer policy.
foreach(_target IN ITEMS unmanaged asan_unmanaged_static asan_unmanaged_shared)
    canon_test_forbid_target_list_value("${_target}" COMPILE_OPTIONS -fsanitize=address)
endforeach()
canon_test_forbid_target_list_value(unmanaged LINK_OPTIONS -fsanitize=address)
