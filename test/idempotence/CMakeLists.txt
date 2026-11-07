# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonIdempotenceFixture LANGUAGES CXX)

include("${CANON_SOURCE_DIR}/test/support/CanonFixture.cmake")

set(_policy_properties
    COMPILE_OPTIONS
    COMPILE_FEATURES
    LINK_OPTIONS
    INTERFACE_COMPILE_FEATURES
    INTERFACE_LINK_OPTIONS
)

# Fails unless running COMMAND again leaves every policy-bearing property of TARGET unchanged.
function(_require_idempotent TARGET COMMAND)
    foreach(_property IN LISTS _policy_properties)
        get_property(_before_${_property} TARGET "${TARGET}" PROPERTY "${_property}")
    endforeach()
    cmake_language(CALL "${COMMAND}" "${TARGET}")
    foreach(_property IN LISTS _policy_properties)
        get_property(_after TARGET "${TARGET}" PROPERTY "${_property}")
        if(NOT "${_after}" STREQUAL "${_before_${_property}}")
            message(FATAL_ERROR
                "${COMMAND}(${TARGET}) changed ${_property} when reapplied\n"
                "  before: '${_before_${_property}}'\n"
                "  after:  '${_after}'")
        endif()
    endforeach()
endfunction()

add_library(object_target OBJECT sample.cpp)
canon_apply_target(object_target)
_require_idempotent(object_target canon_apply_target)

# canon_apply_library() after canon_apply_target() must not reapply the compiled-target policy.
add_library(static_library STATIC sample.cpp)
canon_apply_target(static_library)
canon_apply_library(static_library)
_require_idempotent(static_library canon_apply_target)
_require_idempotent(static_library canon_apply_library)

add_library(interface_library INTERFACE)
canon_apply_library(interface_library)
_require_idempotent(interface_library canon_apply_library)
