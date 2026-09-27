# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(_canon_fixture object)
set(_canon_expected_error "canon_apply_library(): target 'sample' must be a STATIC, SHARED, or MODULE library")
include("${CMAKE_CURRENT_LIST_DIR}/library-error-common.cmake")
