# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationRootFixture LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

canon_add_documentation()
add_subdirectory(nested)

foreach(_target IN ITEMS
    CanonDocumentationRootFixture-doc
    CanonDocumentationRootFixture-doc-clean
    CanonDocumentationNestedFixture-doc
    CanonDocumentationNestedFixture-doc-clean
    doc
    doc-clean
)
    if (NOT TARGET "${_target}")
        message(FATAL_ERROR "Expected documentation target '${_target}' was not created")
    endif()
endforeach()
