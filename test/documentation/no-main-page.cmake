# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves an empty DOXYGEN_USE_MDFILE_AS_MAINPAGE disables the README default and adds no implicit input.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_source "${CANON_SOURCE_DIR}/test/documentation/no-main-page")
set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${_source}" BINARY "${_build}")

file(STRINGS "${_build}/Doxyfile.CanonDocumentationNoMainPageFixture-doc" _input REGEX "^INPUT[\t ]*=")
string(REGEX REPLACE "^INPUT[\t ]*=[\t ]*" "" _input "${_input}")
string(STRIP "${_input}" _input)
if(NOT "${_input}" STREQUAL "${_source}/public.hpp")
    message(FATAL_ERROR "expected Doxygen INPUT to be only '${_source}/public.hpp', got '${_input}'")
endif()

canon_test_build(BINARY "${_build}" TARGET doc)
_canon_read_documentation("${_build}" _html _symbol_html)
canon_test_require_matches("${_html}" "documentation" canonDocumentationNoMainPageMarker)
canon_test_forbid_matches("${_html}" "documentation" CANON_DOCUMENTATION_UNSELECTED_MAIN_PAGE_MARKER)
