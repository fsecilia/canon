# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_CXX_COMPILER
)

# Recreate the consumer with Canon vendored at the same path used by the preset include.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
file(COPY "${CANON_SOURCE_DIR}/test/presets/" DESTINATION "${_source_dir}")
file(MAKE_DIRECTORY "${_source_dir}/external/canon")
file(COPY "${CANON_SOURCE_DIR}/CMakeLists.txt" DESTINATION "${_source_dir}/external/canon")
file(COPY "${CANON_SOURCE_DIR}/cmake" DESTINATION "${_source_dir}/external/canon")
file(WRITE "${_source_dir}/CMakePresets.json"
    "{\n"
    "  \"version\": 10,\n"
    "  \"cmakeMinimumRequired\": {\"major\": 3, \"minor\": 31, \"patch\": 6},\n"
    "  \"include\": [\"external/canon/cmake/CanonPresets.json\"]\n"
    "}\n")

set(_environment_command "${CMAKE_COMMAND}" -E env "CXX=${CANON_CXX_COMPILER}")
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _environment_command "CMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

function(_run DESCRIPTION)
    canon_test_run(
        DESCRIPTION "${DESCRIPTION}"
        COMMAND
            "${CMAKE_COMMAND}"
            -E chdir
            "${_source_dir}"
            ${_environment_command}
            ${ARGN}
    )
endfunction()

function(_expect_cache_value PRESET VARIABLE TYPE EXPECTED_VALUE DESCRIPTION)
    set(_cache "${_source_dir}/build/${PRESET}/CMakeCache.txt")
    if (NOT EXISTS "${_cache}")
        message(FATAL_ERROR "${DESCRIPTION} did not create '${_cache}'")
    endif()

    file(STRINGS "${_cache}" _cache_line REGEX "^${VARIABLE}:${TYPE}=")
    if (NOT "${_cache_line}" STREQUAL "${VARIABLE}:${TYPE}=${EXPECTED_VALUE}")
        message(FATAL_ERROR
            "${DESCRIPTION} configured the wrong ${VARIABLE}: '${_cache_line}'")
    endif()
endfunction()

function(_run_workflow PRESET BUILD_TYPE)
    _run("${PRESET} workflow" "${CMAKE_COMMAND}" --workflow --preset "${PRESET}")
    _expect_cache_value(
        "${PRESET}"
        CMAKE_BUILD_TYPE
        STRING
        "${BUILD_TYPE}"
        "${PRESET} workflow"
    )
    _expect_cache_value(
        "${PRESET}"
        CANON_ENABLE_WARNINGS
        BOOL
        TRUE
        "${PRESET} workflow"
    )
endfunction()
