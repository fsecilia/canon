# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(CANON_FIXTURE quiet)
set(CANON_EXPECTED_ERROR "canon_apply_dependency(): 'QUIET' is inherited")
include("${CMAKE_CURRENT_LIST_DIR}/dependency-error-common.cmake")
