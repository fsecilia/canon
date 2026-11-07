# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves an in-source build fails clearly for a broad input, and works with a narrower one.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_broad "${CANON_TEST_BINARY_DIR}/broad")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/project/" DESTINATION "${_broad}")
canon_test_configure(
    SOURCE "${_broad}"
    BINARY "${_broad}"
    DESCRIPTION "broad in-source documentation configure"
    EXPECT_FAILURE
    EXPECTED_OUTPUT "Canon cannot exclude an in-source build tree without also excluding that input."
)

set(_narrow "${CANON_TEST_BINARY_DIR}/narrow")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/project/" DESTINATION "${_narrow}")
canon_test_configure(
    SOURCE "${_narrow}"
    BINARY "${_narrow}"
    DESCRIPTION "narrow in-source documentation configure"
    ARGS -DCANON_DOCUMENTATION_INPUT=documented.hpp
)
canon_test_build(BINARY "${_narrow}" TARGET doc)
canon_test_require_paths("${_narrow}/doxygen/html/index.html")
