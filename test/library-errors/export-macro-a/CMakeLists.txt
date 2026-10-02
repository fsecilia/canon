# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(Axiom LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../support/CanonSourceFixture.cmake")

add_library(axiom_core STATIC)
set_target_properties(axiom_core PROPERTIES EXPORT_NAME Core)
canon_apply_library(axiom_core)
