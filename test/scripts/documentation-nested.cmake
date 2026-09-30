# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_DOXYGEN_EXECUTABLE
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation-nested")
set(_binary_dir "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_documentation_dir "share/doc/canon-documentation-root-fixture")

# Configure both projects in one build to prove their documentation targets can coexist.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
        "-DCMAKE_INSTALL_DOCDIR=${_documentation_dir}"
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Nested documentation configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

set(_root_output "${_binary_dir}/doxygen")
set(_nested_output "${_binary_dir}/nested/doxygen")

# The root project's qualified target generates only the root project's output tree.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationRootFixture-doc
    RESULT_VARIABLE _root_doc_result
    OUTPUT_VARIABLE _root_doc_stdout
    ERROR_VARIABLE _root_doc_stderr
)
if (NOT "${_root_doc_result}" EQUAL 0)
    message(FATAL_ERROR
        "Root qualified documentation target failed\n"
        "stdout:\n${_root_doc_stdout}\n"
        "stderr:\n${_root_doc_stderr}")
endif()
if (NOT EXISTS "${_root_output}/html/index.html")
    message(FATAL_ERROR "Root qualified documentation target did not generate documentation")
endif()
if (EXISTS "${_nested_output}")
    message(FATAL_ERROR "Root qualified documentation target generated nested documentation")
endif()

# The nested project remains independently buildable inside the enclosing build.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationNestedFixture-doc
    RESULT_VARIABLE _nested_doc_result
    OUTPUT_VARIABLE _nested_doc_stdout
    ERROR_VARIABLE _nested_doc_stderr
)
if (NOT "${_nested_doc_result}" EQUAL 0)
    message(FATAL_ERROR
        "Nested qualified documentation target failed\n"
        "stdout:\n${_nested_doc_stdout}\n"
        "stderr:\n${_nested_doc_stderr}")
endif()
if (NOT EXISTS "${_nested_output}/html/index.html")
    message(FATAL_ERROR "Nested qualified documentation target did not generate documentation")
endif()
file(WRITE "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL" "nested\n")

# The top-level convenience cleanup target owns only the top-level project's output.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc-clean
    RESULT_VARIABLE _clean_result
    OUTPUT_VARIABLE _clean_stdout
    ERROR_VARIABLE _clean_stderr
)
if (NOT "${_clean_result}" EQUAL 0)
    message(FATAL_ERROR
        "Top-level doc-clean target failed\n"
        "stdout:\n${_clean_stdout}\n"
        "stderr:\n${_clean_stderr}")
endif()
if (EXISTS "${_root_output}")
    message(FATAL_ERROR "Top-level doc-clean did not clean the root documentation")
endif()
if (NOT EXISTS "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Top-level doc-clean unexpectedly cleaned nested documentation")
endif()

# The unqualified top-level target is a convenience spelling for the root project only.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if (NOT "${_doc_result}" EQUAL 0)
    message(FATAL_ERROR
        "Top-level doc target failed\n"
        "stdout:\n${_doc_stdout}\n"
        "stderr:\n${_doc_stderr}")
endif()
if (NOT EXISTS "${_root_output}/html/index.html")
    message(FATAL_ERROR "Top-level doc target did not regenerate root documentation")
endif()
if (NOT EXISTS "${_nested_output}/html/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Top-level doc target unexpectedly regenerated nested documentation")
endif()

# The outer project's documentation component must not install nested project output.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --prefix "${_prefix}"
        --component Documentation
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT "${_install_result}" EQUAL 0)
    message(FATAL_ERROR
        "Root documentation install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()
if (NOT EXISTS "${_prefix}/${_documentation_dir}/index.html")
    message(FATAL_ERROR "Root documentation component did not install its generated HTML")
endif()
if (EXISTS "${_prefix}/${_documentation_dir}/NESTED_DOCUMENTATION_SENTINEL")
    message(FATAL_ERROR "Root documentation component installed nested project documentation")
endif()

# The nested cleanup target remains independently usable after the root lifecycle completes.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target CanonDocumentationNestedFixture-doc-clean
    RESULT_VARIABLE _nested_clean_result
    OUTPUT_VARIABLE _nested_clean_stdout
    ERROR_VARIABLE _nested_clean_stderr
)
if (NOT "${_nested_clean_result}" EQUAL 0)
    message(FATAL_ERROR
        "Nested qualified documentation cleanup failed\n"
        "stdout:\n${_nested_clean_stdout}\n"
        "stderr:\n${_nested_clean_stderr}")
endif()
if (EXISTS "${_nested_output}")
    message(FATAL_ERROR "Nested qualified cleanup target did not remove nested documentation")
endif()
