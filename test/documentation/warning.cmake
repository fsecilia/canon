# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves Canon owns the output and warning settings, so a Doxygen warning fails the documentation target.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/documentation/warning" BINARY "${_build}")

set(_doxyfile "${_build}/Doxyfile.CanonDocumentationWarningFixture-doc")
canon_test_require_doxygen_setting("${_doxyfile}" OUTPUT_DIRECTORY "${_build}/doxygen")
canon_test_require_doxygen_setting("${_doxyfile}" HTML_OUTPUT html)
canon_test_require_doxygen_setting("${_doxyfile}" GENERATE_HTML YES)
canon_test_require_doxygen_setting("${_doxyfile}" WARN_AS_ERROR FAIL_ON_WARNINGS)
canon_test_require_doxygen_setting("${_doxyfile}" WARN_LOGFILE "${_build}/doxygen-warnings.log")

canon_test_build(BINARY "${_build}" TARGET doc DESCRIPTION "doc with a Doxygen warning" EXPECT_FAILURE)
file(READ "${_build}/doxygen-warnings.log" _log)
canon_test_require_matches("${_log}" "Doxygen warning log"
    "unable to resolve reference to 'canon_missing_documentation_target'"
)
