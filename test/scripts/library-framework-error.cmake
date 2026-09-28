# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(_canon_fixture framework)
set(_canon_expected_error "canon_apply_library(): FRAMEWORK target 'sample' is not supported")
include("${CMAKE_CURRENT_LIST_DIR}/library-error-common.cmake")
