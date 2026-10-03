# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

canon_test_require_variables(CANON_CLANG_TIDY_EXECUTABLE)

set(_preset "${CANON_PRESET_PROFILE}-tidy")
set(_tidy_configure_command
    "${CMAKE_COMMAND}"
    --preset "${_preset}"
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source_dir}")

_run("${_preset} configure" ${_tidy_configure_command})
_run_workflow("${_preset}" Debug)
_expect_cache_value(
    "${_preset}"
    CANON_CLANG_TIDY_EXECUTABLE
    FILEPATH
    "${CANON_CLANG_TIDY_EXECUTABLE}"
    "${_preset} workflow"
)
_expect_cache_value(
    "${_preset}"
    CANON_ENABLE_TIDY
    BOOL
    TRUE
    "${_preset} workflow"
)
