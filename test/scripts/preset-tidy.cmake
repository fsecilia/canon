# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if (NOT DEFINED CANON_CLANG_TIDY_EXECUTABLE OR "${CANON_CLANG_TIDY_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "CANON_CLANG_TIDY_EXECUTABLE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/preset-common.cmake")

# Give the nested workflow the validated tool and repository configuration without hard-coding a machine-specific path
# in the shared preset.
cmake_path(GET CANON_CLANG_TIDY_EXECUTABLE PARENT_PATH _clang_tidy_directory)
list(APPEND _environment_command "CMAKE_PROGRAM_PATH=${_clang_tidy_directory}")
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source_dir}")

_run_workflow(tidy Debug)
_expect_cache_value(
    tidy
    CANON_ENABLE_TIDY
    BOOL
    TRUE
    "tidy workflow"
)
