# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves caller DOXYGEN_* settings survive, and Canon's exclusions extend rather than replace the caller's.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_source "${CANON_SOURCE_DIR}/test/documentation/policy")
set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${_source}" BINARY "${_build}")

set(_doxyfile "${_build}/Doxyfile.CanonDocumentationPolicyFixture-doc")
foreach(_setting IN ITEMS QUIET JAVADOC_AUTOBRIEF QT_AUTOBRIEF ENABLE_PREPROCESSING)
    canon_test_require_doxygen_setting("${_doxyfile}" "${_setting}" NO)
endforeach()
canon_test_require_doxygen_setting("${_doxyfile}" EXTRACT_ALL YES)
canon_test_require_doxygen_setting("${_doxyfile}" GENERATE_TREEVIEW YES)

file(STRINGS "${_doxyfile}" _input REGEX "^INPUT[\t ]*=")
canon_test_require_matches("${_input}" "Doxygen INPUT" "= ${_source}( |$)" " ${_source}/CUSTOM_MAIN.md( |$)")
file(READ "${_doxyfile}" _doxyfile_text)
foreach(_entry IN ITEMS
    "${CANON_SOURCE_DIR}"
    "${_source}/caller-excluded"
    caller_ignored.hpp
    callerHiddenSymbol
    "${_source}/build"
    "${_source}/out"
    "${_source}/cmake-build-debug"
    "${_source}/external"
    "${_source}/standards"
    "${_source}/test"
    "*_test.cpp"
    "*::detail"
)
    string(FIND "${_doxyfile_text}" "${_entry}" _position)
    if("${_position}" EQUAL -1)
        message(FATAL_ERROR "generated Doxyfile omits '${_entry}'")
    endif()
endforeach()

canon_test_build(BINARY "${_build}" TARGET doc)
_canon_read_documentation("${_build}" _html _symbol_html)
canon_test_require_matches("${_html}" "documentation" CANON_DOCUMENTATION_CALLER_MAIN_PAGE_MARKER)
canon_test_forbid_matches("${_html}" "documentation"
    CANON_DOCUMENTATION_CALLER_EXCLUDE_MARKER
    CANON_DOCUMENTATION_CALLER_BUILD_MARKER
    CANON_DOCUMENTATION_CALLER_OUT_MARKER
    CANON_DOCUMENTATION_CALLER_CMAKE_BUILD_DEBUG_MARKER
    CANON_DOCUMENTATION_CALLER_PATTERN_MARKER
)
canon_test_forbid_matches("${_symbol_html}" "documented symbols" callerHiddenSymbol)
