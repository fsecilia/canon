#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <tool-directory>" >&2
    exit 2
fi

tool_directory=$1
python_executable=${PYTHON:-python}
doxygen_archive="$tool_directory/doxygen-1.18.0.linux.bin.tar.gz"

if [[ -e "$tool_directory" ]]; then
    echo "tool directory already exists: $tool_directory" >&2
    exit 1
fi

mkdir -p "$tool_directory/bin" "$tool_directory/doxygen"
"$python_executable" -m venv "$tool_directory/python"
"$tool_directory/python/bin/python" -m pip install \
    --disable-pip-version-check \
    --only-binary=:all: \
    cmake==3.31.6 \
    clang-tidy==21.1.6 \
    gcovr==8.6

curl --fail --location --silent --show-error \
    --output "$doxygen_archive" \
    https://github.com/doxygen/doxygen/releases/download/Release_1_18_0/doxygen-1.18.0.linux.bin.tar.gz
printf '%s  %s\n' \
    '14fa81bdc34171edb5f1f02b1d60e74802f0439b77fa44e592565d517d72df90' \
    "$doxygen_archive" \
    | sha256sum --check --strict

tar \
    --extract \
    --gzip \
    --file "$doxygen_archive" \
    --directory "$tool_directory/doxygen" \
    --strip-components=1

ln -s ../python/bin/cmake "$tool_directory/bin/cmake"
ln -s ../python/bin/ctest "$tool_directory/bin/ctest"
ln -s ../python/bin/clang-tidy "$tool_directory/bin/clang-tidy"
ln -s ../python/bin/gcovr "$tool_directory/bin/gcovr"
ln -s ../doxygen/bin/doxygen "$tool_directory/bin/doxygen"
