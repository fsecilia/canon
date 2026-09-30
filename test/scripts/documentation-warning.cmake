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
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Documentation warning fixture configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

set(_doxyfile "${_binary_dir}/Doxyfile.CanonDocumentationWarningFixture-doc")

function(_canon_expect_doxygen_setting NAME VALUE)
    file(STRINGS "${_doxyfile}" _setting_lines REGEX "^${NAME}[\t ]*=")
    list(LENGTH _setting_lines _setting_count)
    if (NOT "${_setting_count}" EQUAL 1)
        message(FATAL_ERROR "Expected one Doxygen setting named '${NAME}', found ${_setting_count}")
    endif()
    list(GET _setting_lines 0 _setting_line)
    string(REGEX REPLACE "^[^=]*=[\t ]*" "" _actual_value "${_setting_line}")
    string(STRIP "${_actual_value}" _actual_value)
    if (NOT "${_actual_value}" STREQUAL "${VALUE}")
        message(FATAL_ERROR
            "Expected Canon-owned Doxygen setting '${NAME} = ${VALUE}', found '${_setting_line}'")
    endif()
endfunction()

_canon_expect_doxygen_setting(OUTPUT_DIRECTORY "${_binary_dir}/doxygen")
_canon_expect_doxygen_setting(HTML_OUTPUT html)
_canon_expect_doxygen_setting(GENERATE_HTML YES)
_canon_expect_doxygen_setting(WARN_AS_ERROR FAIL_ON_WARNINGS)
_canon_expect_doxygen_setting(WARN_LOGFILE "${_binary_dir}/doxygen-warnings.log")

# A Doxygen warning must fail the public documentation target.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if ("${_doc_result}" EQUAL 0)
    message(FATAL_ERROR "Documentation target succeeded despite a Doxygen warning")
endif()

set(_warning_log "${_binary_dir}/doxygen-warnings.log")
if (NOT EXISTS "${_warning_log}")
    message(FATAL_ERROR "Documentation failure did not produce '${_warning_log}'")
endif()

file(READ "${_warning_log}" _warning_output)
if (NOT "${_warning_output}" MATCHES "unable to resolve reference to 'canon_missing_documentation_target'")
    message(FATAL_ERROR
        "Documentation target failed without the expected Doxygen warning\n"
        "warning log:\n${_warning_output}\n"
        "stdout:\n${_doc_stdout}\n"
        "stderr:\n${_doc_stderr}")
endif()
