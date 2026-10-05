# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

set(_documentation_dir manual)
_canon_configure_documentation(
    _source_dir
    _binary_dir
    "documentation install configure"
    "-DCMAKE_INSTALL_DOCDIR=${_documentation_dir}"
)

set(_ordinary_prefix "${CANON_TEST_BINARY_DIR}/ordinary-prefix")
set(_generated_prefix "${CANON_TEST_BINARY_DIR}/generated-prefix")

canon_test_run(
    DESCRIPTION "documentation-install fixture build"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}"
)
canon_test_run(
    DESCRIPTION "ordinary install before documentation generation"
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_ordinary_prefix}"
)
if(EXISTS "${_ordinary_prefix}/${_documentation_dir}")
    message(FATAL_ERROR "Ordinary install unexpectedly installed documentation")
endif()

canon_test_run(
    DESCRIPTION "documentation component install before generation"
    EXPECT_FAILURE
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_generated_prefix}"
        --component Documentation
    EXPECTED_OUTPUT doxygen/html
)
canon_test_run(
    DESCRIPTION "documentation build"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --target doc
)

file(REMOVE_RECURSE "${_ordinary_prefix}")
canon_test_run(
    DESCRIPTION "ordinary install after documentation generation"
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --prefix "${_ordinary_prefix}"
)
if(EXISTS "${_ordinary_prefix}/${_documentation_dir}")
    message(FATAL_ERROR "Ordinary install unexpectedly installed generated documentation")
endif()

canon_test_run(
    DESCRIPTION "generated documentation component install"
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_generated_prefix}"
        --component Documentation
)

set(_installed_index "${_generated_prefix}/${_documentation_dir}/index.html")
if(NOT EXISTS "${_installed_index}")
    message(FATAL_ERROR "Documentation component did not install '${_installed_index}'")
endif()
