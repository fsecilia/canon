# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if(NOT "${DependencyFixture_FIND_VERSION_RANGE}" STREQUAL "7.3...<8.0")
    message(FATAL_ERROR "DependencyFixture received version range '${DependencyFixture_FIND_VERSION_RANGE}'")
endif()
add_library(DependencyFixture::Core INTERFACE IMPORTED)
add_library(DependencyFixture::Support INTERFACE IMPORTED)
