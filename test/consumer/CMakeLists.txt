# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonConsumer LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

if (NOT COMMAND canon_apply_target)
    include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")
endif()

if (CANON_ENABLE_ASAN)
    message(FATAL_ERROR "consumer fixture expects CANON_ENABLE_ASAN to default to OFF")
endif()
if (CANON_ENABLE_COVERAGE)
    message(FATAL_ERROR "consumer fixture expects CANON_ENABLE_COVERAGE to default to OFF")
endif()

include("${CANON_SOURCE_DIR}/test/support/CanonFixtureAssertions.cmake")
add_subdirectory(external/noisy)

add_library(sample_static STATIC sample_static.cpp)
set_target_properties(sample_static PROPERTIES EXPORT_NAME CanonConsumer)
add_library(sample_shared SHARED sample_shared.cpp)
set_target_properties(sample_shared PROPERTIES EXPORT_NAME SharedPublic)
add_library(sample_module MODULE sample_module.cpp)
add_library(sample_object OBJECT sample_object.cpp)
add_library(warning_probe STATIC EXCLUDE_FROM_ALL warning_probe.cpp)
add_library(warning_probe_demoted STATIC EXCLUDE_FROM_ALL warning_probe.cpp)
add_library(sample_interface INTERFACE)
target_sources(
    sample_interface
    INTERFACE
        FILE_SET HEADERS
        BASE_DIRS include
        FILES include/sample_interface/sample.hpp
)
target_compile_definitions(sample_interface INTERFACE CANON_SAMPLE_INTERFACE_VALUE=73)
target_compile_features(sample_interface INTERFACE cxx_std_17)

set_target_properties(sample_static PROPERTIES CXX_EXTENSIONS TRUE)
set_target_properties(sample_shared PROPERTIES CXX_EXTENSIONS FALSE)

# Apply library policy where export headers are part of the contract.
foreach(_library IN ITEMS sample_static sample_shared sample_module)
    canon_apply_library("${_library}")
endforeach()

foreach(_target IN ITEMS sample_object warning_probe warning_probe_demoted)
    canon_apply_target("${_target}")
endforeach()

if (CANON_ENABLE_WARNINGS)
    target_compile_options(
        warning_probe_demoted
        PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:-Wno-error=unused-parameter>"
    )
endif()

target_link_libraries(noisy PRIVATE sample_interface)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE sample_static sample_shared sample_interface noisy)
canon_apply_target(consumer)

# Exercise shared-library visibility through unmanaged consumer links.
add_executable(visibility_exported EXCLUDE_FROM_ALL visibility_exported.cpp)
target_link_libraries(visibility_exported PRIVATE sample_shared)

add_executable(visibility_hidden EXCLUDE_FROM_ALL visibility_hidden.cpp)
target_link_libraries(visibility_hidden PRIVATE sample_shared)

# Keep the probes unmanaged while avoiding a module-scanner dependency in the fixture.
set_target_properties(
    visibility_exported visibility_hidden
    PROPERTIES CXX_SCAN_FOR_MODULES FALSE
)

# Verify every managed compiled target receives the shared Canon policy.
get_property(_ipo_supported GLOBAL PROPERTY _CANON_IPO_SUPPORTED)
if (NOT "${_ipo_supported}" STREQUAL "YES" AND NOT "${_ipo_supported}" STREQUAL "NO")
    message(FATAL_ERROR "Canon IPO probe did not record a result: '${_ipo_supported}'")
endif()

set(_compiled_targets
    sample_static
    sample_shared
    sample_module
    sample_object
    warning_probe
    warning_probe_demoted
    consumer
)

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_warning_options
        -Wall
        -Wextra
        -Wpedantic
        -Werror
        -Wstrict-aliasing=2
        -Wdouble-promotion
        -Wfloat-conversion
        -Wshadow
    )
    set(_warning_suppressions)
    set(_warning_reenables)
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_warning_options
        -Weverything
        -Werror
    )
    set(_warning_suppressions
        -Wno-c++98-compat
        -Wno-c++98-compat-pedantic
        -Wno-c++20-compat
        -Wno-ctad-maybe-unsupported
        -Wno-documentation
        -Wno-documentation-unknown-command
        -Wno-exit-time-destructors
        -Wno-global-constructors
        -Wno-missing-prototypes
        -Wno-padded
        -Wno-shadow-field-in-constructor
        -Wno-switch-default
        -Wno-switch-enum
        -Wno-unused-function
        -Wno-unused-member-function
        -Wno-unused-template
    )
    foreach(_optional_warning IN ITEMS
        c++23-compat
        unsafe-buffer-usage-in-libc-call
    )
        _canon_cxx_warning_option_supported("-W${_optional_warning}" _supported)
        if (_supported)
            list(APPEND _warning_suppressions "-Wno-${_optional_warning}")
        endif()
    endforeach()
    set(_warning_reenables
        -Wshadow-field-in-constructor-modified
    )
endif()

foreach(_target IN LISTS _compiled_targets)
    canon_test_require_target_property("${_target}" CXX_SCAN_FOR_MODULES FALSE)
    canon_test_require_target_property("${_target}" CXX_STANDARD 26)
    canon_test_require_target_property("${_target}" CXX_STANDARD_REQUIRED TRUE)
    canon_test_require_target_property("${_target}" POSITION_INDEPENDENT_CODE TRUE)
    canon_test_require_target_property("${_target}" VISIBILITY_INLINES_HIDDEN TRUE)
    canon_test_require_target_property("${_target}" CXX_VISIBILITY_PRESET hidden)

    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"
        OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
            AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU"))
        canon_test_require_cxx_compile_option("${_target}" -fstrict-aliasing)
    endif()

    if (CANON_ENABLE_WARNINGS)
        foreach(_option IN LISTS _warning_options _warning_suppressions _warning_reenables)
            canon_test_require_cxx_compile_option("${_target}" "${_option}")
        endforeach()
        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            canon_test_require_cxx_compile_option_after(
                "${_target}"
                -Wshadow-field-in-constructor-modified
                -Wno-shadow-field-in-constructor
            )
        endif()
    else()
        get_target_property(_options "${_target}" COMPILE_OPTIONS)
        foreach(_option IN LISTS _options)
            if ("${_option}" MATCHES ":-W")
                message(FATAL_ERROR
                    "warnings are disabled but ${_target} has warning option '${_option}'")
            endif()
        endforeach()
    endif()
endforeach()

set(_ipo_final_targets
    sample_shared
    sample_module
    consumer
)
foreach(_target IN LISTS _ipo_final_targets)
    if (_ipo_supported)
        canon_test_require_target_property("${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
    else()
        canon_test_require_target_property_unset(
            "${_target}"
            INTERPROCEDURAL_OPTIMIZATION_RELEASE
        )
    endif()
endforeach()

foreach(_target IN ITEMS sample_static sample_object warning_probe warning_probe_demoted)
    canon_test_require_target_property_unset(
        "${_target}"
        INTERPROCEDURAL_OPTIMIZATION_RELEASE
    )
endforeach()

# Verify every managed library publishes its generated export header as a public file set.
foreach(_library IN ITEMS sample_static sample_shared sample_module)
    get_target_property(_header_sets "${_library}" INTERFACE_HEADER_SETS)
    if (NOT "canon_export_header" IN_LIST _header_sets)
        message(FATAL_ERROR
            "Canon export header for ${_library} is not a public HEADERS file set")
    endif()
endforeach()

canon_test_require_target_property(sample_static CXX_EXTENSIONS TRUE)
canon_test_require_target_property(sample_shared CXX_EXTENSIONS FALSE)
canon_test_require_target_property(sample_interface INTERFACE_COMPILE_DEFINITIONS CANON_SAMPLE_INTERFACE_VALUE=73)
canon_test_require_target_property(sample_interface INTERFACE_COMPILE_FEATURES cxx_std_17)

# Verify Canon does not leak build options through the unmanaged interface target.
foreach(_property IN ITEMS INTERFACE_COMPILE_OPTIONS INTERFACE_LINK_OPTIONS)
    canon_test_require_target_property_empty(sample_interface "${_property}")
endforeach()

# Verify Canon does not modify the unmanaged external target.
canon_test_require_target_property_empty(noisy COMPILE_OPTIONS)
