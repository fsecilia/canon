# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(CANON_FIXTURE required)
set(CANON_EXPECTED_ERROR "canon_apply_dependency(): 'REQUIRED' is inherited")
include("${CMAKE_CURRENT_LIST_DIR}/dependency-error-common.cmake")
