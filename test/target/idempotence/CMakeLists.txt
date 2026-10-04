# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonTargetIdempotence LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

add_library(sample OBJECT "${CMAKE_CURRENT_LIST_DIR}/../../support/empty_main.cpp")
canon_apply_target(sample)
get_property(_compile_options TARGET sample PROPERTY COMPILE_OPTIONS)
get_property(_link_options TARGET sample PROPERTY LINK_OPTIONS)
canon_apply_target(sample)
get_property(_reapplied_compile_options TARGET sample PROPERTY COMPILE_OPTIONS)
get_property(_reapplied_link_options TARGET sample PROPERTY LINK_OPTIONS)

if (NOT "${_reapplied_compile_options}" STREQUAL "${_compile_options}"
    OR NOT "${_reapplied_link_options}" STREQUAL "${_link_options}")
    message(FATAL_ERROR "canon_apply_target() changed target options when reapplied")
endif()
