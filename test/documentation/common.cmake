# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

# Copies the documentation project into this test's tree, so Canon's source-relative exclusions see a fresh layout.
function(_canon_copy_documentation_project OUT_SOURCE)
    set(_source "${CANON_TEST_BINARY_DIR}/source")
    file(COPY "${CANON_SOURCE_DIR}/test/documentation/project/" DESTINATION "${_source}")
    set(${OUT_SOURCE} "${_source}" PARENT_SCOPE)
endfunction()

# Reads generated HTML. OUT_SYMBOLS omits source listings, whose text includes every symbol.
function(_canon_read_documentation BINARY OUT_ALL OUT_SYMBOLS)
    canon_test_read_files(_all "${BINARY}/doxygen/html" "*.html")
    canon_test_read_files(_symbols "${BINARY}/doxygen/html" "*.html" EXCLUDE_REGEX "_source\\.html$")
    set(${OUT_ALL} "${_all}" PARENT_SCOPE)
    set(${OUT_SYMBOLS} "${_symbols}" PARENT_SCOPE)
endfunction()
