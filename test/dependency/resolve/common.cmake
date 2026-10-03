# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)

function(_canon_prepare_required_dependency_fixture OUT_SOURCE_DIR OUT_BUILD_DIR)
    file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
    set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
    set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
    file(MAKE_DIRECTORY "${_source_dir}")
    file(COPY
        "${CANON_SOURCE_DIR}/test/dependency/resolve/project/"
        DESTINATION "${_source_dir}"
    )
    set(${OUT_SOURCE_DIR} "${_source_dir}" PARENT_SCOPE)
    set(${OUT_BUILD_DIR} "${_build_dir}" PARENT_SCOPE)
endfunction()

function(_canon_configure_required_dependency_fixture SOURCE_DIR BUILD_DIR DESCRIPTION)
    canon_test_make_configure_command(
        _configure_command
        "${SOURCE_DIR}"
        "${BUILD_DIR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        ${ARGN}
    )
    canon_test_run(
        DESCRIPTION "${DESCRIPTION}"
        COMMAND ${_configure_command}
    )
endfunction()
