# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include(FindPackageHandleStandardArgs)

set(FixtureGraphics_VERSION 1.3.275)
set(_FixtureGraphics_available TRUE)
find_package_handle_standard_args(
    FixtureGraphics
    REQUIRED_VARS _FixtureGraphics_available
    VERSION_VAR FixtureGraphics_VERSION
    HANDLE_VERSION_RANGE
)

if (FixtureGraphics_FOUND AND NOT TARGET FixtureGraphics::Graphics)
    add_library(FixtureGraphics::Graphics INTERFACE IMPORTED)
    target_compile_definitions(
        FixtureGraphics::Graphics
        INTERFACE CANON_APPLICATION_GRAPHICS_VALUE=13
    )
endif()
