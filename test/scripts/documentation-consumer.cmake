# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_DOXYGEN_EXECUTABLE
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Copy the fixture so its binary tree can live inside the project source tree safely.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_binary_dir "${_source_dir}/out")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/" DESTINATION "${_source_dir}")

# Configure documentation with the active compiler, toolchain, and discovered Doxygen installation.
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${_source_dir}"
    -B "${_binary_dir}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Documentation configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# Generate the documentation and retain output for a useful failure report.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if (NOT _doc_result EQUAL 0)
    message(FATAL_ERROR
        "Documentation build failed\n"
        "stdout:\n${_doc_stdout}\n"
        "stderr:\n${_doc_stderr}")
endif()

set(_html_dir "${_binary_dir}/doxygen/html")
set(_index "${_html_dir}/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "Documentation target did not generate '${_index}'")
endif()

# Read generated pages once so the public and excluded-input contracts can be checked together.
file(GLOB_RECURSE _html_files "${_html_dir}/*.html")
set(_html "")
set(_symbol_html "")
foreach(_file IN LISTS _html_files)
    file(READ "${_file}" _contents)
    string(APPEND _html "\n${_contents}")
    if (NOT _file MATCHES "_source\\.html$")
        string(APPEND _symbol_html "\n${_contents}")
    endif()
endforeach()

if (NOT _html MATCHES "CANON_DOCUMENTATION_MAIN_PAGE_MARKER")
    message(FATAL_ERROR "Documentation output did not use README.md as its main page")
endif()
if (NOT _html MATCHES "documented::answer")
    message(FATAL_ERROR "Documentation output did not contain the documented API")
endif()

foreach(_excluded_symbol IN ITEMS hiddenTopLevelDetail hiddenNestedDetail)
    if (_symbol_html MATCHES "${_excluded_symbol}")
        message(FATAL_ERROR "Documentation output contained excluded symbol '${_excluded_symbol}'")
    endif()
endforeach()

foreach(_visible_symbol IN ITEMS
    visibleTopLevelDetails
    visibleTopLevelDetailHelper
    visibleNestedDetails
    visibleNestedDetailHelper
)
    if (NOT _symbol_html MATCHES "${_visible_symbol}")
        message(FATAL_ERROR "Documentation output omitted public symbol '${_visible_symbol}'")
    endif()
endforeach()

foreach(_excluded_marker IN ITEMS
    CANON_DOCUMENTATION_BINARY_MARKER
    CANON_DOCUMENTATION_BUILD_MARKER
    CANON_DOCUMENTATION_EXTERNAL_MARKER
    CANON_DOCUMENTATION_STANDARDS_MARKER
    CANON_DOCUMENTATION_TEST_MARKER
    CANON_DOCUMENTATION_TEST_PATTERN_MARKER
)
    if (_html MATCHES "${_excluded_marker}")
        message(FATAL_ERROR "Documentation output contained excluded marker '${_excluded_marker}'")
    endif()
endforeach()

# Clean through the public lifecycle target and verify no generated documentation state remains.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc-clean
    RESULT_VARIABLE _clean_result
    OUTPUT_VARIABLE _clean_stdout
    ERROR_VARIABLE _clean_stderr
)
if (NOT _clean_result EQUAL 0)
    message(FATAL_ERROR
        "doc-clean failed\n"
        "stdout:\n${_clean_stdout}\n"
        "stderr:\n${_clean_stderr}")
endif()
if (EXISTS "${_binary_dir}/doxygen" OR EXISTS "${_binary_dir}/doxygen-warnings.log")
    message(FATAL_ERROR "doc-clean did not remove generated documentation state")
endif()
