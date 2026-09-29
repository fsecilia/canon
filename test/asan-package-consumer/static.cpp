// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto asanStaticValue() -> int;

auto main() -> int {
    return asanStaticValue() == 17 ? 0 : 1;
}
