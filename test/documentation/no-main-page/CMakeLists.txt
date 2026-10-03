# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonDocumentationNoMainPageFixture LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "")
canon_add_documentation(public.hpp)
