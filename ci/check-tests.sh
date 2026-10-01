#!/usr/bin/env bash
set -euo pipefail

: "${CC:?CC must name the C compiler}"
: "${CXX:?CXX must name the C++ compiler}"

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root"

cmake --version
ninja --version
"$CC" --version
"$CXX" --version
clang-tidy --version
gcovr --version
doxygen --version

cmake --preset debug
ctest --test-dir build/debug --show-only=json-v1 \
    | python "$repository_root/ci/require-all-tests.py"
cmake --build --preset debug
ctest --preset debug
