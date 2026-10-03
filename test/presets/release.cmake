# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

set(_preset "${CANON_PRESET_PROFILE}-release")
_run_workflow("${_preset}" Release)
