// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

auto childValue() -> int;
auto childVendorValue() -> int;

auto main() -> int {
    return childValue() + childVendorValue() == 0 ? 0 : 1;
}
