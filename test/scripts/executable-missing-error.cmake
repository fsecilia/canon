# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(CANON_FIXTURE missing)
set(CANON_EXPECTED_ERROR "canon_apply_executable(): target 'missing' does not exist")
include("${CMAKE_CURRENT_LIST_DIR}/executable-error-common.cmake")
