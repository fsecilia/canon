# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonCoverageFixture LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

if (NOT CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "coverage fixture requires CANON_ENABLE_COVERAGE=ON")
endif()

include(CTest)

add_library(covered STATIC covered.cpp external/excluded.cpp)
canon_apply_library(covered)

if (NOT TARGET coverage-clean OR NOT TARGET coverage-report)
    message(FATAL_ERROR "coverage helpers were not created for the top-level coverage build")
endif()

add_executable(covered_test covered_test.cpp)
target_link_libraries(covered_test PRIVATE covered)
canon_apply_target(covered_test)
add_test(NAME covered_test COMMAND covered_test)
add_test(
    NAME coverage_project_owned
    COMMAND "${CMAKE_COMMAND}" -E echo "project-owned coverage test"
)

function(_require_compile_option TARGET OPTION)
    get_target_property(_options "${TARGET}" COMPILE_OPTIONS)
    if ("${_options}" STREQUAL "_options-NOTFOUND")
        message(FATAL_ERROR "${TARGET} has no compile options")
    endif()

    set(_required "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
    if (NOT "${_required}" IN_LIST _options)
        message(FATAL_ERROR "${TARGET} is missing coverage compile option '${OPTION}'")
    endif()
endfunction()

# Verify compile instrumentation on every managed target in the fixture.
foreach(_target IN ITEMS covered covered_test)
    _require_compile_option("${_target}" "--coverage")
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        _require_compile_option("${_target}" "-fprofile-abs-path")
    endif()
endforeach()

# Only targets with a real link step need the coverage runtime link option.
get_target_property(_link_options covered_test LINK_OPTIONS)
if (NOT "--coverage" IN_LIST _link_options)
    message(FATAL_ERROR "covered_test is missing the coverage link option")
endif()
