# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonTidyFixture VERSION LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (NOT CANON_ENABLE_TIDY)
    message(FATAL_ERROR "tidy fixture requires CANON_ENABLE_TIDY=ON")
endif()

add_executable(tooling_app tooling.cpp tooling.hpp)
canon_apply_target(tooling_app)

add_executable(tidy_probe EXCLUDE_FROM_ALL tidy_probe.cpp)
canon_apply_target(tidy_probe)

add_subdirectory(external/vendor)

# Verify tidy is attached only to the targets that Canon manages.
get_target_property(_tidy tooling_app CXX_CLANG_TIDY)
if ("${_tidy}" STREQUAL "_tidy-NOTFOUND" OR "${_tidy}" STREQUAL "")
    message(FATAL_ERROR "Canon did not attach clang-tidy to tooling_app")
endif()

get_target_property(_vendor_tidy tooling_vendor CXX_CLANG_TIDY)
if (NOT "${_vendor_tidy}" STREQUAL "_vendor_tidy-NOTFOUND"
    AND NOT "${_vendor_tidy}" STREQUAL "")
    message(FATAL_ERROR "Canon attached clang-tidy to unmanaged tooling_vendor")
endif()
