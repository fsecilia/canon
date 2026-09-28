# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(CANON_FIXTURE bundle)
set(CANON_EXPECTED_ERROR "canon_apply_executable(): MACOSX_BUNDLE target 'sample' is not supported")
include("${CMAKE_CURRENT_LIST_DIR}/executable-error-common.cmake")
