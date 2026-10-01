# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationPolicyFixture LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../support/CanonSourceFixture.cmake")

set(DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/caller-excluded")
set(DOXYGEN_EXCLUDE "${PROJECT_SOURCE_DIR}/caller-excluded")
set(DOXYGEN_EXCLUDE_PATTERNS "caller_ignored.hpp")
set(DOXYGEN_EXCLUDE_SYMBOLS callerHiddenSymbol)
set(DOXYGEN_STRIP_FROM_PATH "${CANON_SOURCE_DIR}")
set(DOXYGEN_QUIET NO)
set(DOXYGEN_JAVADOC_AUTOBRIEF NO)
set(DOXYGEN_QT_AUTOBRIEF NO)
set(DOXYGEN_ENABLE_PREPROCESSING NO)
set(DOXYGEN_EXTRACT_ALL YES)
set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${PROJECT_SOURCE_DIR}/CUSTOM_MAIN.md")
set(DOXYGEN_GENERATE_TREEVIEW YES)

canon_add_documentation()
