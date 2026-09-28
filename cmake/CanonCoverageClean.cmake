# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if (NOT DEFINED CANON_COVERAGE_BINARY_DIR OR "${CANON_COVERAGE_BINARY_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_COVERAGE_BINARY_DIR is required")
endif()

file(GLOB_RECURSE _canon_coverage_data
    LIST_DIRECTORIES FALSE
    "${CANON_COVERAGE_BINARY_DIR}/*.gcda"
)

if (_canon_coverage_data)
    file(REMOVE ${_canon_coverage_data})
endif()
