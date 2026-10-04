// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Frank Secilia

extern "C" char* strcpy(char* destination, char const* source);

namespace {

constexpr int hiddenValue() {
    return 7;
}

} // namespace

template <class T>
constexpr int useHidden(T) {
    return hiddenValue();
}

template <>
constexpr int useHidden(int);

void copyText(char* destination, char const* source) {
    strcpy(destination, source);
}
