# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_PRESET_PROFILE
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

if("${CANON_PRESET_PROFILE}" STREQUAL "gcc")
    set(_compiler_alias g++)
elseif("${CANON_PRESET_PROFILE}" STREQUAL "clang")
    set(_compiler_alias clang++)
else()
    message(FATAL_ERROR "unsupported preset profile '${CANON_PRESET_PROFILE}'")
endif()

set(_compiler_alias_dir "${CANON_TEST_BINARY_DIR}/compiler-alias")
file(MAKE_DIRECTORY "${_compiler_alias_dir}")
file(CREATE_LINK
    "${CANON_CXX_COMPILER}"
    "${_compiler_alias_dir}/${_compiler_alias}"
    SYMBOLIC
)
if(CMAKE_HOST_WIN32)
    set(_path_separator ";")
else()
    set(_path_separator ":")
endif()
set(ENV{PATH} "${_compiler_alias_dir}${_path_separator}$ENV{PATH}")

function(_run DESCRIPTION)
    canon_test_run(
        DESCRIPTION "${DESCRIPTION}"
        COMMAND
            "${CMAKE_COMMAND}"
            -E chdir
            "${_source_dir}"
            ${ARGN}
    )
endfunction()

function(_expect_cache_value PRESET VARIABLE TYPE EXPECTED_VALUE DESCRIPTION)
    set(_cache "${_source_dir}/build/${PRESET}/CMakeCache.txt")
    if(NOT EXISTS "${_cache}")
        message(FATAL_ERROR "${DESCRIPTION} did not create '${_cache}'")
    endif()

    file(STRINGS "${_cache}" _cache_line REGEX "^${VARIABLE}:${TYPE}=")
    if(NOT "${_cache_line}" STREQUAL "${VARIABLE}:${TYPE}=${EXPECTED_VALUE}")
        message(FATAL_ERROR
            "${DESCRIPTION} configured the wrong ${VARIABLE}: '${_cache_line}'")
    endif()
endfunction()

function(_expect_compiler PRESET DESCRIPTION)
    set(_cache "${_source_dir}/build/${PRESET}/CMakeCache.txt")
    if(NOT EXISTS "${_cache}")
        message(FATAL_ERROR "${DESCRIPTION} did not create '${_cache}'")
    endif()

    file(STRINGS "${_cache}" _cache_line REGEX "^CMAKE_CXX_COMPILER:FILEPATH=")
    if("${_cache_line}" STREQUAL "")
        message(FATAL_ERROR "${DESCRIPTION} did not record CMAKE_CXX_COMPILER")
    endif()
    string(REGEX REPLACE "^[^=]*=" "" _configured_compiler "${_cache_line}")

    file(REAL_PATH "${_configured_compiler}" _configured_real)
    file(REAL_PATH "${CANON_CXX_COMPILER}" _expected_real)
    if(NOT "${_configured_real}" STREQUAL "${_expected_real}")
        message(FATAL_ERROR
            "${DESCRIPTION} configured the wrong compiler:\n"
            "  expected: ${_expected_real}\n"
            "  actual:   ${_configured_real}")
    endif()
endfunction()

function(_run_workflow PRESET BUILD_TYPE)
    _run("${PRESET} workflow" "${CMAKE_COMMAND}" --workflow --preset "${PRESET}")
    _expect_compiler("${PRESET}" "${PRESET} workflow")
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
