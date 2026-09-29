# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonIpoUnavailable LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

# Make the first IPO probe fail without leaving invalid flags on the generated targets.
set(_saved_cxx_flags "${CMAKE_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fuse-ld=canon-ipo-probe-missing")

add_library(first SHARED sample.cpp)
canon_apply_target(first)

set(CMAKE_CXX_FLAGS "${_saved_cxx_flags}")

# A non-final-link target must not receive IPO regardless of the cached probe result.
add_library(nonfinal STATIC sample.cpp)
canon_apply_target(nonfinal)

# The cached configure-wide result must keep later final-link targets on the same non-IPO path.
add_library(second SHARED sample.cpp)
canon_apply_target(second)

get_property(_ipo_supported GLOBAL PROPERTY _CANON_IPO_SUPPORTED)
if (NOT _ipo_supported STREQUAL "NO")
    message(FATAL_ERROR "Expected the forced IPO probe to fail, got '${_ipo_supported}'")
endif()

foreach(_target IN ITEMS first nonfinal second)
    get_target_property(_ipo_property "${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE)
    if (NOT "${_ipo_property}" STREQUAL "_ipo_property-NOTFOUND")
        message(FATAL_ERROR "${_target} unexpectedly enables Release IPO")
    endif()
endforeach()
