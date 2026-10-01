#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <tool-directory>" >&2
    exit 2
fi

tool_directory=$1
python_executable=${PYTHON:-python}

if [[ -e "$tool_directory" ]]; then
    echo "tool directory already exists: $tool_directory" >&2
    exit 1
fi

mkdir -p "$tool_directory/bin"
"$python_executable" -m venv "$tool_directory/python"
"$tool_directory/python/bin/python" -m pip install \
    --disable-pip-version-check \
    --only-binary=:all: \
    clang-format==21.1.8
ln -s ../python/bin/clang-format "$tool_directory/bin/clang-format"
