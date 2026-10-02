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
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation/policy")
set(_binary_dir "${CANON_TEST_BINARY_DIR}")

canon_test_run(
    DESCRIPTION "documentation caller-policy configure"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)

set(_doxyfile "${_binary_dir}/Doxyfile.CanonDocumentationPolicyFixture-doc")
if (NOT EXISTS "${_doxyfile}")
    message(FATAL_ERROR "Documentation caller-policy fixture did not generate '${_doxyfile}'")
endif()
file(READ "${_doxyfile}" _doxyfile_contents)

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
            "Expected Doxygen setting '${NAME} = ${VALUE}', found '${_setting_line}'")
    endif()
endfunction()

_canon_expect_doxygen_setting(QUIET NO)
_canon_expect_doxygen_setting(JAVADOC_AUTOBRIEF NO)
_canon_expect_doxygen_setting(QT_AUTOBRIEF NO)
_canon_expect_doxygen_setting(ENABLE_PREPROCESSING NO)
_canon_expect_doxygen_setting(EXTRACT_ALL YES)
_canon_expect_doxygen_setting(GENERATE_TREEVIEW YES)
file(STRINGS "${_doxyfile}" _input_lines REGEX "^INPUT[\t ]*=")
list(LENGTH _input_lines _input_count)
if (NOT "${_input_count}" EQUAL 1)
    message(FATAL_ERROR "Expected one Doxygen INPUT setting, found ${_input_count}")
endif()
list(GET _input_lines 0 _input_line)
foreach(_required_input IN ITEMS "${_source_dir}" "${_source_dir}/CUSTOM_MAIN.md")
    string(FIND "${_input_line}" "${_required_input}" _input_index)
    if ("${_input_index}" EQUAL -1)
        message(FATAL_ERROR "Doxygen INPUT omitted '${_required_input}': ${_input_line}")
    endif()
endforeach()

foreach(_required_text IN ITEMS
    "${CANON_SOURCE_DIR}"
    "${_source_dir}/CUSTOM_MAIN.md"
    "${_source_dir}/caller-excluded"
    "caller_ignored.hpp"
    "callerHiddenSymbol"
    "${_source_dir}/build"
    "${_source_dir}/out"
    "${_source_dir}/cmake-build-debug"
    "${_source_dir}/external"
    "${_source_dir}/standards"
    "${_source_dir}/test"
    "*_test.cpp"
    "*::detail"
)
    string(FIND "${_doxyfile_contents}" "${_required_text}" _required_text_index)
    if ("${_required_text_index}" EQUAL -1)
        message(FATAL_ERROR "Generated Doxyfile omitted '${_required_text}'")
    endif()
endforeach()

canon_test_run(
    DESCRIPTION "documentation caller-policy build"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
)

set(_html_dir "${_binary_dir}/doxygen/html")
file(GLOB_RECURSE _html_files "${_html_dir}/*.html")
set(_html "")
set(_symbol_html "")
foreach(_file IN LISTS _html_files)
    file(READ "${_file}" _contents)
    string(APPEND _html "\n${_contents}")
    if (NOT "${_file}" MATCHES "_source\\.html$")
        string(APPEND _symbol_html "\n${_contents}")
    endif()
endforeach()

if (NOT "${_html}" MATCHES "CANON_DOCUMENTATION_CALLER_MAIN_PAGE_MARKER")
    message(FATAL_ERROR "Documentation output did not use the caller-selected main page")
endif()
foreach(_excluded_marker IN ITEMS
    CANON_DOCUMENTATION_CALLER_EXCLUDE_MARKER
    CANON_DOCUMENTATION_CALLER_BUILD_MARKER
    CANON_DOCUMENTATION_CALLER_OUT_MARKER
    CANON_DOCUMENTATION_CALLER_CMAKE_BUILD_DEBUG_MARKER
    CANON_DOCUMENTATION_CALLER_PATTERN_MARKER
)
    if ("${_html}" MATCHES "${_excluded_marker}")
        message(FATAL_ERROR "Documentation output contained caller-excluded marker '${_excluded_marker}'")
    endif()
endforeach()
if ("${_symbol_html}" MATCHES "callerHiddenSymbol")
    message(FATAL_ERROR "Documentation output contained caller-excluded symbol 'callerHiddenSymbol'")
endif()
