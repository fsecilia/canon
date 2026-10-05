# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.12)

project(CanonPolicyFixture LANGUAGES CXX)

if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

cmake_policy(GET CMP0077 _cmp0077_before)
set(CANON_ENABLE_WARNINGS ON)
include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")
cmake_policy(GET CMP0077 _cmp0077_after)

if(NOT CANON_ENABLE_WARNINGS)
    message(FATAL_ERROR "Canon changed the caller-provided CANON_ENABLE_WARNINGS value")
endif()
if(NOT "${_cmp0077_after}" STREQUAL "${_cmp0077_before}")
    message(FATAL_ERROR
        "Canon changed caller policy CMP0077 from '${_cmp0077_before}' to '${_cmp0077_after}'")
endif()

add_library(policy_fixture STATIC policy.cpp)
canon_apply_target(policy_fixture)
