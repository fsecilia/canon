# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(CanonDocumentationNestedFixture LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../../support/CanonSourceFixture.cmake")
canon_add_documentation(nested.hpp)
