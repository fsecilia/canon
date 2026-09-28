// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto asanStaticValue() -> int;

auto main() -> int {
    auto* value = new int{asanStaticValue()};
    auto const result = *value == 17 ? 0 : 1;
    delete value;
    return result;
}
