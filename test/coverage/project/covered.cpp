// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto classify(int value) -> int;

auto classify(int value) -> int {
    if (value > 0) {
        return 1;
    }

    return 0;
}
