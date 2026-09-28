// SPDX-License-Identifier: MIT

/// \file
/// \copyright Copyright (C) 2026 Frank Secilia

#include "sample.hpp"
#include "sample_interface/sample.hpp"
#include "sample_shared.hpp"
#include "sample_static.hpp"

auto noisy(int unused) -> int;

auto main() -> int {
    return sampleAnswer() == sampleAnswerValue && sampleSharedAnswer() == sampleAnswerValue &&
            sampleInterfaceAnswer() == sampleInterfaceAnswerValue && noisy(0) == sampleInterfaceAnswerValue
        ? 0
        : 1;
}
