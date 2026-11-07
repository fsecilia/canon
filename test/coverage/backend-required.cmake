# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves configuration fails when automatic discovery finds no usable compiler-matched coverage backend.
#
# Each scenario points the fixture at a fake compiler driver that reports a chosen companion program.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_CXX_COMPILER_ID)

if("${CANON_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_program gcov)
    set(_override CANON_GCOV_EXECUTABLE)
    set(_version_text "gcov (GCC) 99.0.0")
else()
    set(_program llvm-cov)
    set(_override CANON_LLVM_COV_EXECUTABLE)
    set(_version_text "LLVM version 99.0.0")
endif()

set(_tools "${CANON_TEST_BINARY_DIR}/tools")
set(_executable_permissions OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

# Writes a fake compiler that reports COMPANION for -print-prog-name=<program> and fails for anything else.
function(_write_fake_compiler PATH COMPANION)
    file(WRITE "${PATH}"
        "#!/bin/sh\n"
        "if [ \"$1\" = \"-print-prog-name=${_program}\" ]; then\n"
        "    printf '%s\\n' '${COMPANION}'\n"
        "    exit 0\n"
        "fi\n"
        "exit 1\n")
    file(CHMOD "${PATH}" PERMISSIONS ${_executable_permissions})
endfunction()

# Configures the fixture with COMPILER, clearing any override so only automatic discovery runs.
function(_configure_with_compiler NAME COMPILER)
    canon_test_configure(
        SOURCE "${CANON_SOURCE_DIR}/test/coverage/backend-required"
        BINARY "${CANON_TEST_BINARY_DIR}/${NAME}"
        DESCRIPTION "${NAME} coverage backend"
        ARGS
            "-DCANON_TEST_COVERAGE_COMPILER=${COMPILER}"
            -DCANON_ENABLE_COVERAGE=ON
            -DCANON_GCOV_EXECUTABLE=
            -DCANON_LLVM_COV_EXECUTABLE=
        EXPECT_FAILURE
        ${ARGN}
    )
endfunction()

set(_missing_backend "${_tools}/missing-${_program}")
_write_fake_compiler("${_tools}/cxx-unresolved" "${_missing_backend}")
_configure_with_compiler(
    unresolved
    "${_tools}/cxx-unresolved"
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable"
        "reported '${_missing_backend}'"
        "that exact program could not be resolved"
        "set ${_override} to the compiler-matched executable"
)

set(_mismatched_backend "${_tools}/${_program}")
file(WRITE "${_mismatched_backend}" "#!/bin/sh\nprintf '%s\\n' '${_version_text}'\n")
file(CHMOD "${_mismatched_backend}" PERMISSIONS ${_executable_permissions})
_write_fake_compiler("${_tools}/cxx-mismatch" "${_mismatched_backend}")
_configure_with_compiler(
    mismatched
    "${_tools}/cxx-mismatch"
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable"
        "reports major version 99"
        "set ${_override} to the compiler-matched executable"
)
