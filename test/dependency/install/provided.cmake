# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/dependency/resolve/common.cmake")

_canon_prepare_required_dependency_fixture(_source_dir _build_dir)
_canon_configure_required_dependency_fixture(
    "${_source_dir}"
    "${_build_dir}"
    "Preprovided dependency runtime-install no-op"
    -DCANON_PROVIDE_CORE=ON
    -DCANON_PROVIDE_SUPPORT=ON
    -DCANON_INSTALL_DEPENDENCY=ON
)
