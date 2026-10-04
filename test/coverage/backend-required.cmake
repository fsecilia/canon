# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_CXX_COMPILER_ID
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}/tools")

if ("${CANON_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_program_name gcov)
    set(_override_variable CANON_GCOV_EXECUTABLE)
    set(_backend_version "gcov (GCC) 99.0.0")
elseif ("${CANON_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_program_name llvm-cov)
    set(_override_variable CANON_LLVM_COV_EXECUTABLE)
    set(_backend_version "LLVM version 99.0.0")
else()
    message(FATAL_ERROR "unsupported test compiler '${CANON_CXX_COMPILER_ID}'")
endif()

set(_missing_backend "${CANON_TEST_BINARY_DIR}/tools/missing-${_program_name}")
set(_unresolved_compiler "${CANON_TEST_BINARY_DIR}/tools/cxx-unresolved")
file(WRITE "${_unresolved_compiler}"
    "#!/bin/sh\n"
    "if [ \"$1\" = \"-print-prog-name=${_program_name}\" ]; then\n"
    "    printf '%s\\n' '${_missing_backend}'\n"
    "    exit 0\n"
    "fi\n"
    "exit 1\n")
file(CHMOD "${_unresolved_compiler}"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

canon_test_make_configure_command(
    _unresolved_configure_command
    "${CANON_SOURCE_DIR}/test/coverage/backend-required"
    "${CANON_TEST_BINARY_DIR}/unresolved"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCANON_TEST_COVERAGE_COMPILER=${_unresolved_compiler}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
)

canon_test_run(
    DESCRIPTION "unresolved coverage backend"
    EXPECT_FAILURE
    COMMAND ${_unresolved_configure_command}
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable"
        "reported '${_missing_backend}'"
        "that exact program could not be resolved"
        "set ${_override_variable} to the compiler-matched executable"
)

set(_fake_backend "${CANON_TEST_BINARY_DIR}/tools/${_program_name}")
file(WRITE "${_fake_backend}" "#!/bin/sh\nprintf '%s\\n' '${_backend_version}'\n")
file(CHMOD "${_fake_backend}"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

set(_mismatch_compiler "${CANON_TEST_BINARY_DIR}/tools/cxx-mismatch")
file(WRITE "${_mismatch_compiler}"
    "#!/bin/sh\n"
    "if [ \"$1\" = \"-print-prog-name=${_program_name}\" ]; then\n"
    "    printf '%s\\n' '${_fake_backend}'\n"
    "    exit 0\n"
    "fi\n"
    "exit 1\n")
file(CHMOD "${_mismatch_compiler}"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

canon_test_make_configure_command(
    _mismatch_configure_command
    "${CANON_SOURCE_DIR}/test/coverage/backend-required"
    "${CANON_TEST_BINARY_DIR}/mismatch"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCANON_TEST_COVERAGE_COMPILER=${_mismatch_compiler}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCANON_ENABLE_COVERAGE=ON
)

canon_test_run(
    DESCRIPTION "mismatched coverage backend"
    EXPECT_FAILURE
    COMMAND ${_mismatch_configure_command}
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable"
        "reports major version 99"
        "set ${_override_variable} to the compiler-matched executable"
)
