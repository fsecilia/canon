// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include "tooling.hpp"

auto toolingAnswer() -> ToolingValue {
    return 73;
}

auto main() -> int {
    return toolingAnswer() == 73 ? 0 : 1;
}
