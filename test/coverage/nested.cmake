# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_SOURCE_DIR)

canon_test_require_variables(
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_GCOVR_EXECUTABLE
)

function(_canon_test_nested_coverage ORDER CHILD_FIRST)
    set(_binary_dir "${CANON_TEST_BINARY_DIR}/${ORDER}")
    file(REMOVE_RECURSE "${_binary_dir}")
    canon_test_make_configure_command(
        _configure_command
        "${CANON_SOURCE_DIR}/test/coverage/nested"
        "${_binary_dir}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCANON_ENABLE_COVERAGE=ON
        "-DCANON_TEST_COVERAGE_CHILD_FIRST=${CHILD_FIRST}"
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
    )
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
    endif()

    canon_test_run(
        DESCRIPTION "nested coverage ${ORDER} configure"
        COMMAND ${_configure_command}
    )
    canon_test_run(
        DESCRIPTION "nested coverage ${ORDER} build"
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}"
    )
    canon_test_run(
        DESCRIPTION "nested coverage ${ORDER} tests"
        COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${_binary_dir}" --output-on-failure
    )
    canon_test_run(
        DESCRIPTION "nested coverage ${ORDER} report"
        COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target coverage-report
    )

    set(_index "${_binary_dir}/coverage/index.html")
    if (NOT EXISTS "${_index}")
        message(FATAL_ERROR "nested coverage-report did not generate ${_index}")
    endif()
    file(READ "${_index}" _html)
    if (NOT "${_html}" MATCHES "root_covered\\.cpp")
        message(FATAL_ERROR
            "coverage report suppressed root project source for ${ORDER}")
    endif()
    if (NOT "${_html}" MATCHES "covered\\.cpp")
        message(FATAL_ERROR
            "coverage report suppressed managed child source beneath root external for ${ORDER}")
    endif()
    if ("${_html}" MATCHES "root_excluded\\.cpp")
        message(FATAL_ERROR
            "coverage report unexpectedly contains root external source for ${ORDER}")
    endif()
    if ("${_html}" MATCHES "excluded\\.cpp")
        message(FATAL_ERROR
            "coverage report unexpectedly contains child external source for ${ORDER}")
    endif()
endfunction()

_canon_test_nested_coverage(root-first OFF)
_canon_test_nested_coverage(child-first ON)
