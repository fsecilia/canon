// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include <canon_application_fixture/engine_export.hpp>
#include <canon_application_fixture/fixture_headers.hpp>

CANON_APPLICATION_ENGINE_API auto engineValue() -> int;

auto main() -> int {
    constexpr auto expectedEngineValue = 31;
    return engineValue() == expectedEngineValue && canon_application_fixture::fixtureHeadersValue() == 7 ? 0 : 1;
}
