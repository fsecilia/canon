# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves documentation installs only as an explicit component, and only after it has been generated.

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

_canon_copy_documentation_project(_source)
set(_build "${CANON_TEST_BINARY_DIR}/build")
set(_ordinary_prefix "${CANON_TEST_BINARY_DIR}/ordinary")
set(_component_prefix "${CANON_TEST_BINARY_DIR}/component")
canon_test_configure(SOURCE "${_source}" BINARY "${_build}" ARGS -DCMAKE_INSTALL_DOCDIR=manual)
canon_test_build(BINARY "${_build}")

canon_test_install(BINARY "${_build}" PREFIX "${_ordinary_prefix}" DESCRIPTION "ordinary install before doc")
canon_test_forbid_paths("${_ordinary_prefix}/manual")
canon_test_install(
    BINARY "${_build}"
    PREFIX "${_component_prefix}"
    COMPONENT Documentation
    DESCRIPTION "documentation component before doc"
    EXPECT_FAILURE
    EXPECTED_OUTPUT doxygen/html
)

canon_test_build(BINARY "${_build}" TARGET doc)
file(REMOVE_RECURSE "${_ordinary_prefix}")
canon_test_install(BINARY "${_build}" PREFIX "${_ordinary_prefix}" DESCRIPTION "ordinary install after doc")
canon_test_forbid_paths("${_ordinary_prefix}/manual")
canon_test_install(BINARY "${_build}" PREFIX "${_component_prefix}" COMPONENT Documentation)
canon_test_require_paths("${_component_prefix}/manual/index.html")
