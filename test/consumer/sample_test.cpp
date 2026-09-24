// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

#include "sample.hpp"

#include <cstdlib>
#include <filesystem>
#include <string_view>

auto main() -> int {
    if (sampleAnswer() != sampleAnswerValue) {
        return 1;
    }

    auto const* environment = std::getenv("CANON_SAMPLE_TEST_MODE");
    if (environment == nullptr) {
        return 2;
    }

    auto const mode = std::string_view{environment};
    if (mode != "basic" && mode != "alternate") {
        return 3;
    }

    if (std::filesystem::current_path().filename() != "sample-test-working-directory") {
        return 4;
    }

    return 0;
}
