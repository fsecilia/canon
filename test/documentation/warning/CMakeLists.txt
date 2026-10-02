# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationWarningFixture LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

set(DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/caller-output")
set(DOXYGEN_HTML_OUTPUT caller-html)
set(DOXYGEN_GENERATE_HTML NO)
set(DOXYGEN_WARN_AS_ERROR NO)
set(DOXYGEN_WARN_LOGFILE "${PROJECT_BINARY_DIR}/caller-warnings.log")

canon_add_documentation(warning.hpp)
