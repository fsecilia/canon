# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(CanonDocumentationNestedFixture LANGUAGES NONE)

include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")
canon_add_documentation(nested.hpp)
