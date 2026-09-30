# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_CXX_COMPILER
    CANON_CXX_COMPILER_ID
    CANON_CXX_COMPILER_FRONTEND_VARIANT
    CANON_CXX_COMPILER_VERSION
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

# Verify family recognition and major-version matching independently of tool discovery.
_canon_validate_coverage_version_output(
    "gcov (GCC) 14.3.0\n"
    GNU
    14
    _valid
    _reason
)
if (NOT _valid)
    message(FATAL_ERROR "matching GNU gcov version was rejected: ${_reason}")
endif()

_canon_validate_coverage_version_output(
    "gcov (GCC) 14.3.0\n"
    GNU
    15
    _valid
    _reason
)
if (_valid OR NOT "${_reason}" MATCHES "reports major version 14")
    message(FATAL_ERROR "GNU gcov major-version mismatch was not diagnosed")
endif()

_canon_validate_coverage_version_output(
    "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
    LLVM
    17
    _valid
    _reason
)
if (NOT _valid)
    message(FATAL_ERROR "matching LLVM llvm-cov version was rejected: ${_reason}")
endif()

_canon_validate_coverage_version_output(
    "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
    GNU
    17
    _valid
    _reason
)
if (_valid OR NOT "${_reason}" MATCHES "GNU gcov")
    message(FATAL_ERROR "coverage-tool family mismatch was not diagnosed")
endif()

# Exact-name resolution must not fall through to a generic coverage companion.
_canon_resolve_reported_coverage_tool(
    canon-nonexistent-coverage-companion
    _resolved_executable
)
if (NOT "${_resolved_executable}" STREQUAL "")
    message(FATAL_ERROR
        "coverage discovery unexpectedly resolved '${_resolved_executable}' for a missing exact name")
endif()

# Automatic discovery may fail, but it must remain a visible soft failure and must not seed an override.
set(CMAKE_CXX_COMPILER "${CMAKE_COMMAND}")
set(CMAKE_CXX_COMPILER_ID "${CANON_CXX_COMPILER_ID}")
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "${CANON_CXX_COMPILER_FRONTEND_VARIANT}")
set(CMAKE_CXX_COMPILER_VERSION "${CANON_CXX_COMPILER_VERSION}")
set(CANON_GCOV_EXECUTABLE "")
set(CANON_LLVM_COV_EXECUTABLE "")
_canon_find_coverage_backend(_backend)
if (NOT "${_backend}" STREQUAL "")
    message(FATAL_ERROR "failed automatic coverage discovery unexpectedly produced '${_backend}'")
endif()
if (NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL ""
    OR NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "automatic coverage discovery populated an explicit override variable")
endif()
