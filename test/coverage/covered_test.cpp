// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto classify(int value) -> int;
auto excludedAnswer() -> int;

auto main() -> int {
    if (classify(7) != 1) {
        return 1;
    }

    return excludedAnswer() == 73 ? 0 : 1;
}
