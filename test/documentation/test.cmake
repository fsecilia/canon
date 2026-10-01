# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_DOXYGEN_EXECUTABLE
    CANON_TEST_CASE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_binary_dir "${_source_dir}/out")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/" DESTINATION "${_source_dir}")

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

if ("${CANON_TEST_CASE}" STREQUAL "install")
    set(_documentation_dir manual)
    list(APPEND _configure_command "-DCMAKE_INSTALL_DOCDIR=${_documentation_dir}")
endif()

canon_test_run(
    DESCRIPTION "documentation ${CANON_TEST_CASE} configure"
    COMMAND ${_configure_command}
)

if ("${CANON_TEST_CASE}" STREQUAL "consumer")
    canon_test_run(
        DESCRIPTION "documentation build"
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
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
        CANON_DOCUMENTATION_BUILD_MARKER
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
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc-clean
    )
    if (EXISTS "${_binary_dir}/doxygen" OR EXISTS "${_binary_dir}/doxygen-warnings.log")
        message(FATAL_ERROR "doc-clean did not remove generated documentation state")
    endif()
elseif ("${CANON_TEST_CASE}" STREQUAL "install")
    set(_ordinary_prefix "${CANON_TEST_BINARY_DIR}/ordinary-prefix")
    set(_generated_prefix "${CANON_TEST_BINARY_DIR}/generated-prefix")

    canon_test_run(
        DESCRIPTION "documentation-install fixture build"
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}"
    )
    canon_test_run(
        DESCRIPTION "ordinary install before documentation generation"
        COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --prefix "${_ordinary_prefix}"
    )
    if (EXISTS "${_ordinary_prefix}/${_documentation_dir}")
        message(FATAL_ERROR "Ordinary install unexpectedly installed documentation")
    endif()

    canon_test_run(
        DESCRIPTION "documentation component install before generation"
        EXPECT_FAILURE
        COMMAND
            "${CMAKE_COMMAND}"
            --install "${_binary_dir}"
            --prefix "${_generated_prefix}"
            --component Documentation
        EXPECTED_OUTPUT doxygen/html
    )
    canon_test_run(
        DESCRIPTION "documentation build"
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    )

    file(REMOVE_RECURSE "${_ordinary_prefix}")
    canon_test_run(
        DESCRIPTION "ordinary install after documentation generation"
        COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --prefix "${_ordinary_prefix}"
    )
    if (EXISTS "${_ordinary_prefix}/${_documentation_dir}")
        message(FATAL_ERROR "Ordinary install unexpectedly installed generated documentation")
    endif()

    canon_test_run(
        DESCRIPTION "generated documentation component install"
        COMMAND
            "${CMAKE_COMMAND}"
            --install "${_binary_dir}"
            --prefix "${_generated_prefix}"
            --component Documentation
    )

    set(_installed_index "${_generated_prefix}/${_documentation_dir}/index.html")
    if (NOT EXISTS "${_installed_index}")
        message(FATAL_ERROR "Documentation component did not install '${_installed_index}'")
    endif()
else()
    message(FATAL_ERROR "Unknown documentation test case '${CANON_TEST_CASE}'")
endif()
