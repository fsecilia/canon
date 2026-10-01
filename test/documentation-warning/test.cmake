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
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation-warning")
set(_binary_dir "${CANON_TEST_BINARY_DIR}")

canon_test_run(
    DESCRIPTION "documentation warning fixture configure"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)

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

canon_test_run(
    DESCRIPTION "documentation target with Doxygen warning"
    EXPECT_FAILURE
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
)

set(_warning_log "${_binary_dir}/doxygen-warnings.log")
if (NOT EXISTS "${_warning_log}")
    message(FATAL_ERROR "Documentation failure did not produce '${_warning_log}'")
endif()

file(READ "${_warning_log}" _warning_output)
if (NOT "${_warning_output}" MATCHES "unable to resolve reference to 'canon_missing_documentation_target'")
    message(FATAL_ERROR
        "Documentation target failed without the expected Doxygen warning\n"
        "warning log:\n${_warning_output}")
endif()
