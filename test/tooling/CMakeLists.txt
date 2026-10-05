# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonTidyFixture LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

if(NOT CANON_ENABLE_TIDY)
    message(FATAL_ERROR "tidy fixture requires CANON_ENABLE_TIDY=ON")
endif()

add_executable(tooling_app tooling.cpp tooling.hpp)
canon_apply_target(tooling_app)

add_executable(tidy_probe EXCLUDE_FROM_ALL tidy_probe.cpp)
canon_apply_target(tidy_probe)

add_library(tidy_warning_policy OBJECT EXCLUDE_FROM_ALL tidy_warning_policy.cpp)
canon_apply_target(tidy_warning_policy)

if(DEFINED CANON_SECOND_CLANG_TIDY_EXECUTABLE
    AND NOT "${CANON_SECOND_CLANG_TIDY_EXECUTABLE}" STREQUAL "")
    set(
        CANON_CLANG_TIDY_EXECUTABLE
        "${CANON_SECOND_CLANG_TIDY_EXECUTABLE}"
        CACHE FILEPATH "clang-tidy executable used by Canon"
        FORCE
    )
endif()

add_executable(tidy_header_probe EXCLUDE_FROM_ALL tidy_header_probe.cpp tidy_header_probe.hpp)
canon_apply_target(tidy_header_probe)

add_subdirectory(external/vendor)

# Verify tidy is attached only to the targets that Canon manages.
get_target_property(_tidy tooling_app CXX_CLANG_TIDY)
if("${_tidy}" STREQUAL "_tidy-NOTFOUND" OR "${_tidy}" STREQUAL "")
    message(FATAL_ERROR "Canon did not attach clang-tidy to tooling_app")
endif()

get_target_property(_vendor_tidy tooling_vendor CXX_CLANG_TIDY)
if(NOT "${_vendor_tidy}" STREQUAL "_vendor_tidy-NOTFOUND"
    AND NOT "${_vendor_tidy}" STREQUAL "")
    message(FATAL_ERROR "Canon attached clang-tidy to unmanaged tooling_vendor")
endif()

if(CANON_ENABLE_WARNINGS)
    foreach(_expected_tidy_argument IN ITEMS
        --extra-arg=-Wno-unused-function
        --extra-arg=-Wno-unsafe-buffer-usage-in-libc-call
        --extra-arg=-Wshadow-field-in-constructor-modified
    )
        if(NOT "${_expected_tidy_argument}" IN_LIST _tidy)
            message(FATAL_ERROR
                "Canon clang-tidy command is missing warning-policy argument "
                "'${_expected_tidy_argument}'")
        endif()
    endforeach()
endif()
