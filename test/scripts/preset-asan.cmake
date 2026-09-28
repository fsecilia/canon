# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CMAKE_CURRENT_LIST_DIR}/preset-common.cmake")

_run_workflow(asan Debug)
_expect_cache_value(
    asan
    CANON_ENABLE_ASAN
    BOOL
    TRUE
    "asan workflow"
)
