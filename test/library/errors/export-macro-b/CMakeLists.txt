# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

project(AxiomCore LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../../support/CanonSourceFixture.cmake")

add_library(axiom_core_monolith STATIC)
set_target_properties(axiom_core_monolith PROPERTIES EXPORT_NAME AxiomCore)
canon_apply_library(axiom_core_monolith)
