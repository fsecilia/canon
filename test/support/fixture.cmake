# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Drives one fixture through the lifecycle stages its registration requests.
#
# Configure always runs. When configure is expected to fail, nothing else runs. Otherwise the fixture is optionally
# built, installed, and checked against the install manifest it recorded.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_TEST_FIXTURE_DIR)

set(_binary_dir "${CANON_TEST_BINARY_DIR}/build")
if(CANON_TEST_LONG_PATH)
    # Push generated paths well past typical command-line and path-length comfort zones.
    string(LENGTH "${_binary_dir}" _length)
    math(EXPR _padding_length "200 - ${_length}")
    if(_padding_length LESS 16)
        set(_padding_length 16)
    endif()
    string(REPEAT x "${_padding_length}" _padding)
    set(_binary_dir "${CANON_TEST_BINARY_DIR}/${_padding}/build")
endif()
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

set(_expectations)
if(CANON_TEST_EXPECT_FAILURE)
    list(APPEND _expectations EXPECT_FAILURE)
endif()
if(CANON_TEST_EXPECTED_OUTPUT)
    list(APPEND _expectations EXPECTED_OUTPUT ${CANON_TEST_EXPECTED_OUTPUT})
endif()

canon_test_configure(
    SOURCE "${CANON_TEST_FIXTURE_DIR}"
    BINARY "${_binary_dir}"
    ARGS
        "-DCANON_TEST_CASE_FILE=${CANON_TEST_CASE_FILE}"
        "-DCMAKE_INSTALL_PREFIX=${_install_prefix}"
    ${_expectations}
)
if(CANON_TEST_EXPECT_FAILURE)
    return()
endif()

if(CANON_TEST_BUILD)
    canon_test_build(BINARY "${_binary_dir}")
endif()

if(CANON_TEST_INSTALL_TARGET)
    canon_test_build(BINARY "${_binary_dir}" TARGET "${CANON_TEST_INSTALL_TARGET}")
elseif(CANON_TEST_INSTALL)
    canon_test_install(BINARY "${_binary_dir}" PREFIX "${_install_prefix}")
endif()
if(CANON_TEST_INSTALL_TARGET OR CANON_TEST_INSTALL)
    canon_test_check_install_manifest("${_binary_dir}" "${_install_prefix}")
endif()
