# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_DOXYGEN_EXECUTABLE
)

function(_canon_configure_documentation OUT_SOURCE_DIR OUT_BINARY_DIR DESCRIPTION)
    file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
    set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
    set(_binary_dir "${_source_dir}/out")
    file(COPY "${CANON_SOURCE_DIR}/test/documentation/" DESTINATION "${_source_dir}")

    canon_test_make_configure_command(
        _configure_command
        "${_source_dir}"
        "${_binary_dir}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        -DCMAKE_BUILD_TYPE=Debug
        "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
        ${ARGN}
    )

    canon_test_run(
        DESCRIPTION "${DESCRIPTION}"
        COMMAND ${_configure_command}
    )

    set(${OUT_SOURCE_DIR} "${_source_dir}" PARENT_SCOPE)
    set(${OUT_BINARY_DIR} "${_binary_dir}" PARENT_SCOPE)
endfunction()
