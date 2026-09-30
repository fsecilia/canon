# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(CANON_FIXTURE no-package)
set(CANON_EXPECTED_ERROR "package dependencies were declared, but project")
include("${CMAKE_CURRENT_LIST_DIR}/dependency-error-common.cmake")
