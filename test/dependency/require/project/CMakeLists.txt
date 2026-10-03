# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonRequiredDependency LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")

if (CANON_PROVIDE_CORE)
    add_library(DependencyFixture::Core INTERFACE IMPORTED GLOBAL)
endif()
if (CANON_PROVIDE_SUPPORT)
    add_library(DependencyFixture::Support INTERFACE IMPORTED GLOBAL)
endif()

canon_require_dependency(
    fixture-dependency
    PACKAGE DependencyFixture
    VERSION "7.3...<8.0"
    TARGETS
        DependencyFixture::Core
        DependencyFixture::Support
)

foreach(_required_target IN ITEMS DependencyFixture::Core DependencyFixture::Support)
    if (NOT TARGET "${_required_target}")
        message(FATAL_ERROR "Required dependency target '${_required_target}' is unavailable")
    endif()
endforeach()
