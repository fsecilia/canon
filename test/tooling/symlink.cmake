# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves the external/ header exclusion still applies when the project is reached through a symlink.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_link "${CANON_TEST_BINARY_DIR}/source")
file(CREATE_LINK "${CANON_SOURCE_DIR}/test" "${_link}" SYMBOLIC)

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${_link}/tooling" BINARY "${_build}")
canon_test_build(BINARY "${_build}")
