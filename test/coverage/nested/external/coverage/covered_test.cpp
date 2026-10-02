// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto nestedClassify(int value) -> int;
auto nestedExcludedAnswer() -> int;

auto main() -> int {
    if (nestedClassify(7) != 1) {
        return 1;
    }

    return nestedExcludedAnswer() == 73 ? 0 : 1;
}
