# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonAsanFixture LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if (NOT CANON_ENABLE_ASAN)
    message(FATAL_ERROR "ASan fixture requires CANON_ENABLE_ASAN=ON")
endif()

include(CTest)

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
    get_target_property(_compile_options "${_target}" COMPILE_OPTIONS)
    foreach(_option IN ITEMS -fsanitize=address -fno-omit-frame-pointer)
        string(FIND "${_compile_options}" "${_option}" _position)
        if ("${_position}" EQUAL -1)
            message(FATAL_ERROR "${_target} is missing ASan compile option '${_option}'")
        endif()
    endforeach()
endforeach()

# Verify each managed target publishes the sanitizer runtime where its consumers need it.
get_target_property(_static_link_options asan_static INTERFACE_LINK_OPTIONS)
if (NOT "-fsanitize=address" IN_LIST _static_link_options)
    message(FATAL_ERROR "asan_static does not publish the ASan link requirement")
endif()

get_target_property(_shared_link_options asan_shared LINK_OPTIONS)
get_target_property(_shared_interface_link_options asan_shared INTERFACE_LINK_OPTIONS)
foreach(_options IN ITEMS _shared_link_options _shared_interface_link_options)
    if (NOT "-fsanitize=address" IN_LIST ${_options})
        message(FATAL_ERROR "asan_shared is missing an ASan link requirement")
    endif()
endforeach()

foreach(_target IN ITEMS asan_app asan_test asan_probe)
    get_target_property(_link_options "${_target}" LINK_OPTIONS)
    if (NOT "-fsanitize=address" IN_LIST _link_options)
        message(FATAL_ERROR "${_target} is missing the ASan link option")
    endif()
endforeach()

# Keep unmanaged target state untouched by Canon's sanitizer compile policy.
foreach(_target IN ITEMS unmanaged asan_unmanaged_static asan_unmanaged_shared)
    get_target_property(_unmanaged_options "${_target}" COMPILE_OPTIONS)
    if (NOT "${_unmanaged_options}" STREQUAL "_unmanaged_options-NOTFOUND"
        AND "-fsanitize=address" IN_LIST _unmanaged_options)
        message(FATAL_ERROR "${_target} inherited ASan compile instrumentation")
    endif()
endforeach()

# Keep the unrelated unmanaged library untouched by Canon's sanitizer link policy.
get_target_property(_unmanaged_link_options unmanaged LINK_OPTIONS)
if (NOT "${_unmanaged_link_options}" STREQUAL "_unmanaged_link_options-NOTFOUND"
    AND "-fsanitize=address" IN_LIST _unmanaged_link_options)
    message(FATAL_ERROR "unmanaged inherited the ASan link option")
endif()
