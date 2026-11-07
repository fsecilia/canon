// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

auto dependencyFixtureSupport() -> int;

auto dependencyFixtureRuntime() -> int {
    return dependencyFixtureSupport();
}
