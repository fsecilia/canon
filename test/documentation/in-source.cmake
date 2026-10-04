# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_DOXYGEN_EXECUTABLE
)

set(_broad_source_dir "${CANON_TEST_BINARY_DIR}/broad")
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/project/" DESTINATION "${_broad_source_dir}")

canon_test_make_configure_command(
    _broad_configure_command
    "${_broad_source_dir}"
    "${_broad_source_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)
canon_test_run(
    DESCRIPTION "broad in-source documentation configure"
    EXPECT_FAILURE
    COMMAND ${_broad_configure_command}
    EXPECTED_OUTPUT
        "Canon cannot exclude an in-source build tree without also excluding that input."
)

set(_narrow_source_dir "${CANON_TEST_BINARY_DIR}/narrow")
file(COPY "${CANON_SOURCE_DIR}/test/documentation/project/" DESTINATION "${_narrow_source_dir}")

canon_test_make_configure_command(
    _narrow_configure_command
    "${_narrow_source_dir}"
    "${_narrow_source_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
    "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
    -DCANON_DOCUMENTATION_INPUT=documented.hpp
)
canon_test_run(
    DESCRIPTION "narrow in-source documentation configure"
    COMMAND ${_narrow_configure_command}
)
canon_test_run(
    DESCRIPTION "narrow in-source documentation build"
    COMMAND "${CMAKE_COMMAND}" --build "${_narrow_source_dir}" --config "${CANON_TEST_CONFIG}" --target doc
)

set(_index "${_narrow_source_dir}/doxygen/html/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "Narrow in-source documentation did not generate '${_index}'")
endif()
