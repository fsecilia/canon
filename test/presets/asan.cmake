# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

_run_workflow(asan Debug)
_expect_cache_value(
    asan
    CANON_ENABLE_ASAN
    BOOL
    TRUE
    "asan workflow"
)
