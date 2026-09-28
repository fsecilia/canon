// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include "sample_interface/sample.hpp"

// Intentionally warning-prone to verify Canon policy does not affect unmanaged targets.
auto noisy(int unused) -> int {
    return sampleInterfaceAnswer();
}
