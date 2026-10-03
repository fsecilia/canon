// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto rootClassify(int value) -> int;
auto rootExcludedAnswer() -> int;

auto main() -> int {
    if (rootClassify(7) != 1) {
        return 1;
    }

    return rootExcludedAnswer() == 73 ? 0 : 1;
}
