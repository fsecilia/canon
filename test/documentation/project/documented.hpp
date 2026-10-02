// SPDX-License-Identifier: MIT

/// \file
/// \brief Defines the public API used by the documentation fixture.
/// \copyright Copyright (C) 2026 Frank Secilia

#pragma once

namespace detail {

/// Must not appear in generated documentation.
auto hiddenTopLevelDetail() -> int;

} // namespace detail

namespace details {

/// Must remain visible despite the similar namespace name.
auto visibleTopLevelDetails() -> int;

} // namespace details

namespace detail_helper {

/// Must remain visible despite the similar namespace name.
auto visibleTopLevelDetailHelper() -> int;

} // namespace detail_helper

namespace documented {

/// Returns the documented fixture answer.
auto answer() -> int;

namespace detail {

/// Must not appear in generated documentation.
auto hiddenNestedDetail() -> int;

} // namespace detail

namespace details {

/// Must remain visible despite the similar namespace name.
auto visibleNestedDetails() -> int;

} // namespace details

namespace detail_helper {

/// Must remain visible despite the similar namespace name.
auto visibleNestedDetailHelper() -> int;

} // namespace detail_helper

} // namespace documented
