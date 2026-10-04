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

configure_args=(--preset debug)
if [[ -n ${CANON_CI_GCOV_EXECUTABLE:-} ]]; then
    gcov_executable=$(command -v -- "$CANON_CI_GCOV_EXECUTABLE") || {
        echo "coverage backend not found: $CANON_CI_GCOV_EXECUTABLE" >&2
        exit 1
    }
    configure_args+=("-DCANON_GCOV_EXECUTABLE=$gcov_executable")
fi
if [[ -n ${CANON_CI_LLVM_COV_EXECUTABLE:-} ]]; then
    llvm_cov_executable=$(command -v -- "$CANON_CI_LLVM_COV_EXECUTABLE") || {
        echo "coverage backend not found: $CANON_CI_LLVM_COV_EXECUTABLE" >&2
        exit 1
    }
    configure_args+=("-DCANON_LLVM_COV_EXECUTABLE=$llvm_cov_executable")
fi

cmake "${configure_args[@]}"
ctest --test-dir build/debug --show-only=json-v1 \
    | python "$repository_root/ci/require-all-tests.py"
cmake --build --preset debug
ctest --preset debug
