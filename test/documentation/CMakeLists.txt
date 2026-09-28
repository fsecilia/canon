# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationFixture LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

add_library(documented STATIC documented.cpp documented.hpp)
canon_apply_library(documented)

# Put documented input in the binary tree so the test can prove Canon excludes it.
file(WRITE "${PROJECT_BINARY_DIR}/ignored_generated.hpp"
    "/// \\file\n"
    "/// CANON_DOCUMENTATION_BINARY_MARKER\n"
    "auto ignoredGeneratedSymbol() -> int;\n"
)

if (CANON_ENABLE_DOCUMENTATION)
    canon_add_documentation()
endif()
