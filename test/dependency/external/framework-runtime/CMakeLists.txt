# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

add_library(framework_runtime SHARED "${PROJECT_SOURCE_DIR}/sample.cpp")
set_target_properties(framework_runtime PROPERTIES FRAMEWORK TRUE)
add_library(DependencyFixture::Runtime ALIAS framework_runtime)
