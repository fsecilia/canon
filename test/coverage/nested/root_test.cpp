// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

auto rootValue() -> int;
auto rootVendorValue() -> int;

auto main() -> int {
    return rootValue() + rootVendorValue() == 0 ? 0 : 1;
}
