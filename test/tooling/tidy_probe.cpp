// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

// Deliberately violates the configured function-naming rule to prove clang-tidy runs.
auto TidyProbe() -> int {
    return 7;
}

auto main() -> int {
    return TidyProbe() == 7 ? 0 : 1;
}
