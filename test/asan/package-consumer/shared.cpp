// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto asanSharedValue() -> int;

auto main() -> int {
    return asanSharedValue() == 23 ? 0 : 1;
}
