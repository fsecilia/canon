// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

#include "sample.hpp"

#include <sample_interface/sample.hpp>

auto noisy(int unused) -> int;

auto main() -> int {
    return sampleAnswer() == sampleAnswerValue && sampleInterfaceAnswer() == sampleInterfaceAnswerValue &&
            noisy(0) == sampleInterfaceAnswerValue
        ? 0
        : 1;
}
