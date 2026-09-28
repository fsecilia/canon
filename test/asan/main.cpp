// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto asanStaticValue() -> int;
auto asanSharedValue() -> int;
auto unmanagedValue() -> int;

auto main() -> int {
    return asanStaticValue() == 17 && asanSharedValue() == 23 && unmanagedValue() == 5 ? 0 : 1;
}
