# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationUnavailableFixture LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")

canon_add_documentation(CMakeLists.txt)
