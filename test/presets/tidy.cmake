# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

canon_test_require_variables(CANON_CLANG_TIDY_EXECUTABLE)

# Seed the tidy build tree with the exact executable validated by the outer project.
_run(
    "tidy configure"
    "${CMAKE_COMMAND}"
    --preset tidy
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source_dir}")

_run_workflow(tidy Debug)
_expect_cache_value(
    tidy
    CANON_CLANG_TIDY_EXECUTABLE
    FILEPATH
    "${CANON_CLANG_TIDY_EXECUTABLE}"
    "tidy workflow"
)
_expect_cache_value(
    tidy
    CANON_ENABLE_TIDY
    BOOL
    TRUE
    "tidy workflow"
)
