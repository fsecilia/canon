# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

set(_preset "${CANON_PRESET_PROFILE}-asan")
_run_workflow("${_preset}" Debug)
_expect_cache_value(
    "${_preset}"
    CANON_ENABLE_ASAN
    BOOL
    TRUE
    "${_preset} workflow"
)
