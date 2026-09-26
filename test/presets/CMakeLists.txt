# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonPresetFixture VERSION 0.1.0 LANGUAGES CXX)

include(CTest)
add_subdirectory(external/canon EXCLUDE_FROM_ALL)

add_library(preset_library STATIC preset.cpp)
canon_apply_target(preset_library)

add_executable(preset_app main.cpp)
target_link_libraries(preset_app PRIVATE preset_library)
canon_apply_target(preset_app)

# Exercise the shared test presets without assuming produced binaries run on the host.
add_test(NAME preset.workflow COMMAND "${CMAKE_COMMAND}" -E true)
