// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

auto rootValue() -> int;
auto ownedValue() -> int;
auto ownedVendorValue() -> int;

auto main() -> int {
    return rootValue() + ownedValue() + ownedVendorValue() == 0 ? 0 : 1;
}
