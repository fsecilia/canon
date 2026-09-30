# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if (NOT DEFINED CANON_COVERAGE_SUMMARY_FILE OR "${CANON_COVERAGE_SUMMARY_FILE}" STREQUAL "")
    message(FATAL_ERROR "CANON_COVERAGE_SUMMARY_FILE is required")
endif()
if (NOT EXISTS "${CANON_COVERAGE_SUMMARY_FILE}")
    message(FATAL_ERROR
        "Canon coverage report did not produce summary '${CANON_COVERAGE_SUMMARY_FILE}'")
endif()

file(READ "${CANON_COVERAGE_SUMMARY_FILE}" _summary)
string(JSON _file_count ERROR_VARIABLE _json_error LENGTH "${_summary}" files)
if (NOT "${_json_error}" STREQUAL "NOTFOUND")
    message(FATAL_ERROR
        "Canon could not read coverage summary '${CANON_COVERAGE_SUMMARY_FILE}': ${_json_error}")
endif()
if (_file_count EQUAL 0)
    message(FATAL_ERROR "Canon coverage report contains no project source files")
endif()

file(REMOVE "${CANON_COVERAGE_SUMMARY_FILE}")
