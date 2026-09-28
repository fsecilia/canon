# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CMAKE_CURRENT_LIST_DIR}/preset-common.cmake")

_run("Preset listing" "${CMAKE_COMMAND}" --list-presets=all)
foreach(_preset IN ITEMS debug release asan tidy)
    if (NOT _run_stdout MATCHES "\"${_preset}\"")
        message(FATAL_ERROR "Preset listing did not expose '${_preset}'")
    endif()
endforeach()
if (_run_stdout MATCHES "\"_canon-base\"")
    message(FATAL_ERROR "Preset listing unexpectedly exposed hidden preset '_canon-base'")
endif()
