// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include <canon_asan_fixture/asan_shared/export.hpp>

CANON_ASAN_FIXTURE_ASAN_SHARED_API auto asanSharedValue() -> int;

CANON_ASAN_FIXTURE_ASAN_SHARED_API auto asanSharedValue() -> int {
    return 23;
}
