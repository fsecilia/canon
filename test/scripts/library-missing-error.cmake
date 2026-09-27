# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(_canon_fixture missing)
set(_canon_expected_error "canon_apply_library(): target 'missing' does not exist")
include("${CMAKE_CURRENT_LIST_DIR}/library-error-common.cmake")
