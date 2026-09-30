// SPDX-License-Identifier: MIT

/// \file
/// \brief Provides symbols for the Doxygen caller-policy fixture.
/// \copyright Copyright (C) 2026 Frank Secilia

#pragma once

/// Remains visible in generated documentation.
inline constexpr auto callerVisibleSymbol = 17;

/// Must be excluded by the caller's symbol policy.
inline constexpr auto callerHiddenSymbol = 19;
