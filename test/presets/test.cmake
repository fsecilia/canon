# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Runs one shared preset workflow in a consumer that vendors Canon at the path its preset include expects.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_PRESET_PROFILE CANON_PRESET_INTENT)

set(_preset "${CANON_PRESET_PROFILE}-${CANON_PRESET_INTENT}")
set(_source "${CANON_TEST_BINARY_DIR}/source")
set(_build "${_source}/build/${_preset}")

file(COPY "${CANON_SOURCE_DIR}/test/presets/" DESTINATION "${_source}" PATTERN test.cmake EXCLUDE)
file(COPY "${CANON_SOURCE_DIR}/CMakeLists.txt" "${CANON_SOURCE_DIR}/cmake" DESTINATION "${_source}/external/canon")
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source}")
file(WRITE "${_source}/CMakePresets.json" [=[
{
  "version": 10,
  "cmakeMinimumRequired": {"major": 3, "minor": 31, "patch": 6},
  "include": ["external/canon/cmake/CanonPresets.json"]
}
]=])

# The presets name plain compiler executables, so put the test compiler on PATH under the name the profile uses.
if("${CANON_PRESET_PROFILE}" STREQUAL "gcc")
    set(_compiler_name g++)
else()
    set(_compiler_name clang++)
endif()
set(_compiler_dir "${CANON_TEST_BINARY_DIR}/compiler")
file(MAKE_DIRECTORY "${_compiler_dir}")
file(CREATE_LINK "${CANON_CXX_COMPILER}" "${_compiler_dir}/${_compiler_name}" SYMBOLIC)
if(CMAKE_HOST_WIN32)
    set(ENV{PATH} "${_compiler_dir};$ENV{PATH}")
else()
    set(ENV{PATH} "${_compiler_dir}:$ENV{PATH}")
endif()

# Each intent's build type and the Canon features it must enable.
set(_build_type Debug)
set(_enabled CANON_ENABLE_WARNINGS)
if("${CANON_PRESET_INTENT}" STREQUAL "release")
    set(_build_type Release)
elseif("${CANON_PRESET_INTENT}" STREQUAL "rel-with-deb-info")
    set(_build_type RelWithDebInfo)
elseif("${CANON_PRESET_INTENT}" STREQUAL "asan")
    list(APPEND _enabled CANON_ENABLE_ASAN)
elseif("${CANON_PRESET_INTENT}" STREQUAL "tidy")
    list(APPEND _enabled CANON_ENABLE_TIDY)
elseif("${CANON_PRESET_INTENT}" STREQUAL "coverage")
    list(APPEND _enabled CANON_ENABLE_COVERAGE)
elseif(NOT "${CANON_PRESET_INTENT}" STREQUAL "debug")
    message(FATAL_ERROR "unknown preset intent '${CANON_PRESET_INTENT}'")
endif()

# Workflows accept no cache arguments, so seed tool overrides with a preset configure first.
if(CANON_TEST_TOOL_ARGUMENTS)
    canon_test_run(
        DESCRIPTION "${_preset} configure with tool overrides"
        COMMAND "${CMAKE_COMMAND}" -E chdir "${_source}" "${CMAKE_COMMAND}" --preset "${_preset}" ${CANON_TEST_TOOL_ARGUMENTS}
    )
endif()
canon_test_run(
    DESCRIPTION "${_preset} workflow"
    COMMAND "${CMAKE_COMMAND}" -E chdir "${_source}" "${CMAKE_COMMAND}" --workflow --preset "${_preset}"
)

canon_test_cache_value(_compiler "${_build}" CMAKE_CXX_COMPILER)
file(REAL_PATH "${_compiler}" _compiler)
file(REAL_PATH "${CANON_CXX_COMPILER}" _expected_compiler)
if(NOT "${_compiler}" STREQUAL "${_expected_compiler}")
    message(FATAL_ERROR "${_preset} configured compiler '${_compiler}', expected '${_expected_compiler}'")
endif()

canon_test_cache_value(_configured_build_type "${_build}" CMAKE_BUILD_TYPE)
if(NOT "${_configured_build_type}" STREQUAL "${_build_type}")
    message(FATAL_ERROR "${_preset} configured CMAKE_BUILD_TYPE '${_configured_build_type}', expected '${_build_type}'")
endif()
foreach(_feature IN ITEMS CANON_ENABLE_WARNINGS CANON_ENABLE_ASAN CANON_ENABLE_TIDY CANON_ENABLE_COVERAGE)
    if("${_feature}" IN_LIST _enabled)
        set(_expected TRUE)
    else()
        set(_expected OFF)
    endif()
    canon_test_cache_value(_value "${_build}" "${_feature}")
    if(NOT "${_value}" STREQUAL "${_expected}")
        message(FATAL_ERROR "${_preset} configured ${_feature}='${_value}', expected '${_expected}'")
    endif()
endforeach()

if("${CANON_PRESET_INTENT}" STREQUAL "coverage")
    canon_test_require_paths("${_build}/coverage/index.html")
endif()
