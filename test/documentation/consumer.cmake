# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/documentation/common.cmake")

_canon_configure_documentation(_source_dir _binary_dir "documentation consumer configure")

canon_test_run(
    DESCRIPTION "documentation build"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --target doc
)

set(_html_dir "${_binary_dir}/doxygen/html")
set(_index "${_html_dir}/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "Documentation target did not generate '${_index}'")
endif()

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

if (NOT "${_html}" MATCHES "CANON_DOCUMENTATION_MAIN_PAGE_MARKER")
    message(FATAL_ERROR "Documentation output did not use README.md as its main page")
endif()
if (NOT "${_html}" MATCHES "documented::answer")
    message(FATAL_ERROR "Documentation output did not contain the documented API")
endif()
if (NOT "${_html}" MATCHES "CANON_DOCUMENTATION_BUILD_MARKER")
    message(FATAL_ERROR
        "Documentation output unexpectedly excluded the source-side build directory")
endif()

foreach(_excluded_symbol IN ITEMS hiddenTopLevelDetail hiddenNestedDetail)
    if ("${_symbol_html}" MATCHES "${_excluded_symbol}")
        message(FATAL_ERROR "Documentation output contained excluded symbol '${_excluded_symbol}'")
    endif()
endforeach()

foreach(_visible_symbol IN ITEMS
    visibleTopLevelDetails
    visibleTopLevelDetailHelper
    visibleNestedDetails
    visibleNestedDetailHelper
)
    if (NOT "${_symbol_html}" MATCHES "${_visible_symbol}")
        message(FATAL_ERROR "Documentation output omitted public symbol '${_visible_symbol}'")
    endif()
endforeach()

foreach(_excluded_marker IN ITEMS
    CANON_DOCUMENTATION_BINARY_MARKER
    CANON_DOCUMENTATION_EXTERNAL_MARKER
    CANON_DOCUMENTATION_STANDARDS_MARKER
    CANON_DOCUMENTATION_TEST_MARKER
    CANON_DOCUMENTATION_TEST_PATTERN_MARKER
)
    if ("${_html}" MATCHES "${_excluded_marker}")
        message(FATAL_ERROR "Documentation output contained excluded marker '${_excluded_marker}'")
    endif()
endforeach()

canon_test_run(
    DESCRIPTION "documentation clean"
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --config "${CANON_TEST_CONFIG}" --target doc-clean
)
if (EXISTS "${_binary_dir}/doxygen" OR EXISTS "${_binary_dir}/doxygen-warnings.log")
    message(FATAL_ERROR "doc-clean did not remove generated documentation state")
endif()
