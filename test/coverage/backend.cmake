# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Exercises coverage-backend validation directly, without a configured project.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")
include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

canon_test_require_variables(CANON_CXX_COMPILER_ID CANON_CXX_COMPILER_FRONTEND_VARIANT CANON_CXX_COMPILER_VERSION)

# Fails unless validating OUTPUT as FAMILY at EXPECTED_MAJOR gives VALID and, when invalid, a reason matching REASON.
function(_require_validation OUTPUT FAMILY EXPECTED_MAJOR VALID REASON)
    _canon_validate_coverage_version_output("${OUTPUT}" "${FAMILY}" "${EXPECTED_MAJOR}" _valid _reason)
    if(NOT "${_valid}" STREQUAL "${VALID}" OR NOT "${_reason}" MATCHES "${REASON}")
        message(FATAL_ERROR
            "validating '${OUTPUT}' as ${FAMILY} ${EXPECTED_MAJOR}: expected ${VALID} matching '${REASON}', "
            "got ${_valid} '${_reason}'")
    endif()
endfunction()

_require_validation("gcov (GCC) 14.3.0\n" GNU 14 TRUE "^$")
_require_validation("gcov (GCC) 14.3.0\n" GNU 15 FALSE "reports major version 14")
_require_validation("LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n" LLVM 17 TRUE "^$")
_require_validation("LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n" GNU 17 FALSE "GNU gcov")

_canon_resolve_reported_coverage_tool(canon-nonexistent-coverage-companion _resolved)
if(NOT "${_resolved}" STREQUAL "")
    message(FATAL_ERROR "coverage discovery resolved '${_resolved}' for a missing exact name")
endif()

# A compiler that cannot report its companion must produce a diagnostic, and must not populate the overrides.
block()
    set(CMAKE_CXX_COMPILER "${CANON_TEST_BINARY_DIR}/missing-cxx-compiler")
    set(CMAKE_CXX_COMPILER_ID "${CANON_CXX_COMPILER_ID}")
    set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "${CANON_CXX_COMPILER_FRONTEND_VARIANT}")
    set(CMAKE_CXX_COMPILER_VERSION "${CANON_CXX_COMPILER_VERSION}")
    set(CANON_GCOV_EXECUTABLE "")
    set(CANON_LLVM_COV_EXECUTABLE "")

    _canon_find_coverage_backend(_backend _reason)
    if(NOT "${_backend}" STREQUAL "")
        message(FATAL_ERROR "failed automatic coverage discovery produced '${_backend}'")
    endif()
    if(NOT "${_reason}" MATCHES "did not report a usable")
        message(FATAL_ERROR "failed automatic coverage discovery did not explain the failure: '${_reason}'")
    endif()
    if(NOT "${CANON_GCOV_EXECUTABLE}${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        message(FATAL_ERROR "automatic coverage discovery populated an explicit override variable")
    endif()
endblock()
