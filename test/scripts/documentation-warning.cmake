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

# Configure the warning fixture with the same Doxygen installation validated by the outer project.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation-warning")
set(_binary_dir "${CANON_TEST_BINARY_DIR}")

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Documentation warning fixture configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# A Doxygen warning must fail the public documentation target.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if (_doc_result EQUAL 0)
    message(FATAL_ERROR "Documentation target succeeded despite a Doxygen warning")
endif()

set(_warning_log "${_binary_dir}/doxygen-warnings.log")
if (NOT EXISTS "${_warning_log}")
    message(FATAL_ERROR "Documentation failure did not produce '${_warning_log}'")
endif()

file(READ "${_warning_log}" _warning_output)
if (NOT _warning_output MATCHES "unable to resolve reference to 'canon_missing_documentation_target'")
    message(FATAL_ERROR
        "Documentation target failed without the expected Doxygen warning\n"
        "warning log:\n${_warning_output}\n"
        "stdout:\n${_doc_stdout}\n"
        "stderr:\n${_doc_stderr}")
endif()
