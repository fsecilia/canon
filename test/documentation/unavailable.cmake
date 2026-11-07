# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves a missing Doxygen fails only the doc target, with instructions, and leaves everything else working.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/documentation/unavailable"
    BINARY "${_build}"
    ARGS -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=TRUE
)
canon_test_build(BINARY "${_build}")
canon_test_install(BINARY "${_build}" PREFIX "${CANON_TEST_BINARY_DIR}/install")
canon_test_build(BINARY "${_build}" TARGET doc-clean)
canon_test_build(
    BINARY "${_build}"
    TARGET doc
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "Doxygen 1.9 or newer was not found when this build tree was configured."
        "Install Doxygen 1.9 or newer and reconfigure before building the doc target."
)
