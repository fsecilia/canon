# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves Canon's default documentation inputs, exclusions, and settings for a project documented from its root.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

_canon_copy_documentation_project(_source)
# A source-side build/ directory is ordinary input; only the active binary tree is excluded.
set(_build "${_source}/out")
canon_test_configure(SOURCE "${_source}" BINARY "${_build}")

set(_doxyfile "${_build}/Doxyfile.CanonDocumentationFixture-doc")
foreach(_setting IN ITEMS QUIET JAVADOC_AUTOBRIEF QT_AUTOBRIEF ENABLE_PREPROCESSING)
    canon_test_require_doxygen_setting("${_doxyfile}" "${_setting}" YES)
endforeach()
canon_test_require_doxygen_setting("${_doxyfile}" EXTRACT_ALL NO)
canon_test_require_doxygen_setting("${_doxyfile}" STRIP_FROM_PATH "${_source}")

canon_test_build(BINARY "${_build}" TARGET doc)
# README.md is also ordinary input here, so only index.html shows whether it became the main page.
file(READ "${_build}/doxygen/html/index.html" _index)
canon_test_require_matches("${_index}" "documentation main page" CANON_DOCUMENTATION_MAIN_PAGE_MARKER)
_canon_read_documentation("${_build}" _html _symbol_html)
canon_test_require_matches("${_html}" "documentation"
    "documented::answer"
    CANON_DOCUMENTATION_BUILD_MARKER
)
canon_test_forbid_matches("${_html}" "documentation"
    CANON_DOCUMENTATION_BINARY_MARKER
    CANON_DOCUMENTATION_EXTERNAL_MARKER
    CANON_DOCUMENTATION_STANDARDS_MARKER
    CANON_DOCUMENTATION_TEST_MARKER
    CANON_DOCUMENTATION_TEST_PATTERN_MARKER
)
# detail namespaces are hidden at every depth, while similarly named namespaces stay visible.
canon_test_forbid_matches("${_symbol_html}" "documented symbols" hiddenTopLevelDetail hiddenNestedDetail)
canon_test_require_matches("${_symbol_html}" "documented symbols"
    visibleTopLevelDetails
    visibleTopLevelDetailHelper
    visibleNestedDetails
    visibleNestedDetailHelper
)

canon_test_build(BINARY "${_build}" TARGET doc-clean)
canon_test_forbid_paths("${_build}/doxygen" "${_build}/doxygen-warnings.log")
