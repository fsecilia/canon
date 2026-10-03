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
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation/no-main-page")

canon_test_run(
    DESCRIPTION "documentation no-main-page configure"
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)

set(_doxyfile
    "${CANON_TEST_BINARY_DIR}/Doxyfile.CanonDocumentationNoMainPageFixture-doc")
if (NOT EXISTS "${_doxyfile}")
    message(FATAL_ERROR "Documentation no-main-page fixture did not generate '${_doxyfile}'")
endif()

file(STRINGS "${_doxyfile}" _input_lines REGEX "^INPUT[\t ]*=")
list(LENGTH _input_lines _input_count)
if (NOT "${_input_count}" EQUAL 1)
    message(FATAL_ERROR "Expected one Doxygen INPUT setting, found ${_input_count}")
endif()
list(GET _input_lines 0 _input_line)
string(FIND "${_input_line}" "${_source_dir}/public.hpp" _public_input_index)
if ("${_public_input_index}" EQUAL -1)
    message(FATAL_ERROR "Doxygen INPUT omitted the explicit public.hpp input: ${_input_line}")
endif()
string(FIND "${_input_line}" "${_source_dir}/README.md" _readme_input_index)
if (NOT "${_readme_input_index}" EQUAL -1)
    message(FATAL_ERROR "Doxygen INPUT unexpectedly contains the disabled README main page: ${_input_line}")
endif()
string(FIND "${_input_line}" "${_source_dir} " _root_input_index)
if (NOT "${_root_input_index}" EQUAL -1)
    message(FATAL_ERROR "Doxygen INPUT unexpectedly contains the project root: ${_input_line}")
endif()

canon_test_run(
    DESCRIPTION "documentation no-main-page build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target doc
)

file(GLOB_RECURSE _html_files "${CANON_TEST_BINARY_DIR}/doxygen/html/*.html")
set(_html "")
foreach(_file IN LISTS _html_files)
    file(READ "${_file}" _contents)
    string(APPEND _html "\n${_contents}")
endforeach()
if ("${_html}" MATCHES "CANON_DOCUMENTATION_UNSELECTED_MAIN_PAGE_MARKER")
    message(FATAL_ERROR "Documentation output unexpectedly used the disabled README main page")
endif()
if (NOT "${_html}" MATCHES "canonDocumentationNoMainPageMarker")
    message(FATAL_ERROR "Documentation output omitted the explicit public.hpp input")
endif()
