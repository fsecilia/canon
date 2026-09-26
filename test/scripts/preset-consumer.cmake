# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_CXX_COMPILER
    CANON_TEST_CASE
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

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
    execute_process(
        COMMAND ${_environment_command} ${ARGN}
        WORKING_DIRECTORY "${_source_dir}"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )
    if (NOT _result EQUAL 0)
        message(FATAL_ERROR
            "${DESCRIPTION} failed\n"
            "stdout:\n${_stdout}\n"
            "stderr:\n${_stderr}")
    endif()

    set(_run_stdout "${_stdout}" PARENT_SCOPE)
endfunction()

if ("${CANON_TEST_CASE}" STREQUAL "listings")
    _run("Preset listing" "${CMAKE_COMMAND}" --list-presets=all)
    foreach(_preset IN ITEMS debug release)
        if (NOT _run_stdout MATCHES "\"${_preset}\"")
            message(FATAL_ERROR "Preset listing did not expose '${_preset}'")
        endif()
    endforeach()
    if (_run_stdout MATCHES "\"_canon-base\"")
        message(FATAL_ERROR "Preset listing unexpectedly exposed hidden preset '_canon-base'")
    endif()
    return()
endif()

if ("${CANON_TEST_CASE}" STREQUAL "debug")
    set(_expected_build_type Debug)
elseif ("${CANON_TEST_CASE}" STREQUAL "release")
    set(_expected_build_type Release)
else()
    message(FATAL_ERROR "Unknown preset test case '${CANON_TEST_CASE}'")
endif()

_run("${_expected_build_type} workflow" "${CMAKE_COMMAND}" --workflow --preset "${CANON_TEST_CASE}")

set(_cache "${_source_dir}/build/${CANON_TEST_CASE}/CMakeCache.txt")
if (NOT EXISTS "${_cache}")
    message(FATAL_ERROR "${_expected_build_type} workflow did not create '${_cache}'")
endif()

file(STRINGS "${_cache}" _build_type_line REGEX "^CMAKE_BUILD_TYPE:STRING=")
if (NOT "${_build_type_line}" STREQUAL "CMAKE_BUILD_TYPE:STRING=${_expected_build_type}")
    message(FATAL_ERROR
        "${_expected_build_type} workflow configured the wrong build type: '${_build_type_line}'")
endif()
