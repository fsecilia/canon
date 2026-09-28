// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include <asan_shared/export.hpp>

asan_shared_api auto asanSharedValue() -> int;

asan_shared_api auto asanSharedValue() -> int {
    return 23;
}
