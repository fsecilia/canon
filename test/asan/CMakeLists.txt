# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonAsanFixture VERSION LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

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

add_executable(asan_probe EXCLUDE_FROM_ALL asan_probe.cpp)
canon_apply_target(asan_probe)

# Verify the compile policy reaches each managed target involved in the fixture.
foreach(_target IN ITEMS asan_static asan_shared asan_app asan_test asan_probe)
    get_target_property(_compile_options "${_target}" COMPILE_OPTIONS)
    foreach(_option IN ITEMS -fsanitize=address -fno-omit-frame-pointer)
        string(FIND "${_compile_options}" "${_option}" _position)
        if (_position EQUAL -1)
            message(FATAL_ERROR "${_target} is missing ASan compile option '${_option}'")
        endif()
    endforeach()
endforeach()

# Verify the executable and shared-library link steps receive the sanitizer runtime.
foreach(_target IN ITEMS asan_shared asan_app asan_test asan_probe)
    get_target_property(_link_options "${_target}" LINK_OPTIONS)
    if (NOT "-fsanitize=address" IN_LIST _link_options)
        message(FATAL_ERROR "${_target} is missing the ASan link option")
    endif()
endforeach()

# Keep unmanaged target state untouched by Canon's sanitizer policy.
foreach(_property IN ITEMS COMPILE_OPTIONS LINK_OPTIONS)
    get_target_property(_unmanaged_options unmanaged "${_property}")
    if (NOT "${_unmanaged_options}" STREQUAL "_unmanaged_options-NOTFOUND"
        AND "-fsanitize=address" IN_LIST _unmanaged_options)
        message(FATAL_ERROR "unmanaged target inherited ASan through ${_property}")
    endif()
endforeach()
