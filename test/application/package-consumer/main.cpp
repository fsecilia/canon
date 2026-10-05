// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include <canon_application_fixture/fixture_headers.hpp>

auto main() -> int {
    return canon_application_fixture::fixtureHeadersValue() == 7 ? 0 : 1;
}
