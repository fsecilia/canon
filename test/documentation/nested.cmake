# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves each project owns its documentation targets, and only the top-level project feeds doc, doc-clean, and the
# Documentation install component.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_docdir share/doc/canon-documentation-root-fixture)
set(_root_output "${_build}/doxygen")
set(_nested_output "${_build}/nested/doxygen")
set(_sentinel "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL")

canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/documentation/nested"
    BINARY "${_build}"
    ARGS "-DCMAKE_INSTALL_DOCDIR=${_docdir}"
)

canon_test_build(BINARY "${_build}" TARGET CanonDocumentationRootFixture-doc)
canon_test_require_paths("${_root_output}/html/index.html")
canon_test_forbid_paths("${_nested_output}")
canon_test_read_files(_root_html "${_root_output}/html" "*.html")
canon_test_forbid_matches("${_root_html}" "root documentation" nestedDocumentationProbe nested_8hpp)

canon_test_build(BINARY "${_build}" TARGET CanonDocumentationNestedFixture-doc)
canon_test_require_paths("${_nested_output}/html/index.html")
file(WRITE "${_sentinel}" "nested\n")

canon_test_build(BINARY "${_build}" TARGET doc-clean)
canon_test_forbid_paths("${_root_output}")
canon_test_require_paths("${_sentinel}")

canon_test_build(BINARY "${_build}" TARGET doc)
canon_test_require_paths("${_root_output}/html/index.html" "${_sentinel}")

canon_test_install(BINARY "${_build}" PREFIX "${_prefix}" COMPONENT Documentation)
canon_test_require_paths("${_prefix}/${_docdir}/index.html")
canon_test_forbid_paths("${_prefix}/${_docdir}/NESTED_DOCUMENTATION_SENTINEL")

canon_test_build(BINARY "${_build}" TARGET CanonDocumentationNestedFixture-doc-clean)
canon_test_forbid_paths("${_nested_output}")
