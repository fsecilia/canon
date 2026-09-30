# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_DOXYGEN_EXECUTABLE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation-nested")
set(_binary_dir "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_documentation_dir "share/doc/canon-documentation-root-fixture")
set(_root_output "${_binary_dir}/doxygen")
set(_nested_output "${_binary_dir}/nested/doxygen")

canon_test_run(
    DESCRIPTION "nested documentation configure"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
        "-DCMAKE_INSTALL_DOCDIR=${_documentation_dir}"
)

canon_test_run(
    DESCRIPTION "root qualified documentation target"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationRootFixture-doc
)
if (NOT EXISTS "${_root_output}/html/index.html")
    message(FATAL_ERROR "Root qualified documentation target did not generate documentation")
endif()
if (EXISTS "${_nested_output}")
    message(FATAL_ERROR "Root qualified documentation target generated nested documentation")
endif()

canon_test_run(
    DESCRIPTION "nested qualified documentation target"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationNestedFixture-doc
)
if (NOT EXISTS "${_nested_output}/html/index.html")
    message(FATAL_ERROR "Nested qualified documentation target did not generate documentation")
endif()
file(WRITE "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL" "nested\n")

canon_test_run(
    DESCRIPTION "top-level documentation clean"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc-clean
)
if (EXISTS "${_root_output}")
    message(FATAL_ERROR "Top-level doc-clean did not clean the root documentation")
endif()
if (NOT EXISTS "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Top-level doc-clean unexpectedly cleaned nested documentation")
endif()

canon_test_run(
    DESCRIPTION "top-level documentation target"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
)
if (NOT EXISTS "${_root_output}/html/index.html")
    message(FATAL_ERROR "Top-level doc target did not regenerate root documentation")
endif()
if (NOT EXISTS "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Top-level doc target unexpectedly regenerated nested documentation")
endif()

canon_test_run(
    DESCRIPTION "root documentation component install"
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --prefix "${_prefix}"
        --component Documentation
)
if (NOT EXISTS "${_prefix}/${_documentation_dir}/index.html")
    message(FATAL_ERROR "Root documentation component did not install its generated HTML")
endif()
if (EXISTS "${_prefix}/${_documentation_dir}/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Root documentation component installed nested project documentation")
endif()

canon_test_run(
    DESCRIPTION "nested qualified documentation cleanup"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationNestedFixture-doc-clean
)
if (EXISTS "${_nested_output}")
    message(FATAL_ERROR "Nested qualified cleanup target did not remove nested documentation")
endif()
