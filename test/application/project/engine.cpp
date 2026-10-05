// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include <canon_application_fixture/engine_export.hpp>
#include <canon_application_fixture/fixture_headers.hpp>

#ifndef CANON_APPLICATION_GRAPHICS_VALUE
#error "Fixture graphics usage requirements did not reach engine"
#endif

auto fixtureRuntimeValue() -> int;

CANON_APPLICATION_ENGINE_API auto engineValue() -> int {
    return canon_application_fixture::fixtureHeadersValue() + fixtureRuntimeValue() + CANON_APPLICATION_GRAPHICS_VALUE;
}
