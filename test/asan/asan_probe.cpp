// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

auto main(int argc, char**) -> int {
    auto* value = new int{argc};
    delete value;

    // Deliberately reuse after free so ASan detects it.
    return *value;
}
