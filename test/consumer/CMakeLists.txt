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

include(CTest)
add_subdirectory(external/noisy)

add_library(sample_static STATIC sample_static.cpp)
set_target_properties(sample_static PROPERTIES EXPORT_NAME CanonConsumer)
add_library(sample_shared SHARED sample_shared.cpp)
set_target_properties(sample_shared PROPERTIES EXPORT_NAME SharedPublic)
add_library(sample_module MODULE sample_module.cpp)
add_library(sample_object OBJECT sample_object.cpp)
add_library(warning_probe STATIC EXCLUDE_FROM_ALL warning_probe.cpp)
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

foreach(_target IN ITEMS sample_object warning_probe)
    canon_apply_target("${_target}")
endforeach()

target_link_libraries(noisy PRIVATE sample_interface)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE sample_static sample_shared sample_interface noisy)
canon_apply_target(consumer)

add_executable(sample_test sample_test.cpp)
target_link_libraries(sample_test PRIVATE sample_static)
canon_apply_target(sample_test)

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

# Give the project-owned CTest cases a known working directory.
set(_sample_test_working_dir "${CMAKE_CURRENT_BINARY_DIR}/sample-test-working-directory")
file(MAKE_DIRECTORY "${_sample_test_working_dir}")

add_test(NAME sample_test.basic COMMAND sample_test basic)
set_tests_properties(
    sample_test.basic
    PROPERTIES
        ENVIRONMENT "CANON_SAMPLE_TEST_MODE=basic"
        WORKING_DIRECTORY "${_sample_test_working_dir}"
)

add_test(NAME sample_test.alternate COMMAND sample_test alternate)
set_tests_properties(
    sample_test.alternate
    PROPERTIES
        ENVIRONMENT "CANON_SAMPLE_TEST_MODE=alternate"
        WORKING_DIRECTORY "${_sample_test_working_dir}"
)

# Verify the consumer owns and registers its expected CTest cases.
get_property(_registered_tests DIRECTORY PROPERTY TESTS)
list(SORT _registered_tests)
set(_expected_tests sample_test.alternate sample_test.basic)
if (NOT "${_registered_tests}" STREQUAL "${_expected_tests}")
    message(FATAL_ERROR
        "Consumer CTest registration: expected '${_expected_tests}', got '${_registered_tests}'")
endif()

function(_require_target_property TARGET PROPERTY EXPECTED)
    get_target_property(_actual "${TARGET}" "${PROPERTY}")
    if (NOT "${_actual}" STREQUAL "${EXPECTED}")
        message(FATAL_ERROR
            "${TARGET} property ${PROPERTY}: expected '${EXPECTED}', got '${_actual}'")
    endif()
endfunction()

function(_require_compile_option TARGET OPTION)
    get_target_property(_options "${TARGET}" COMPILE_OPTIONS)
    if ("${_options}" STREQUAL "_options-NOTFOUND")
        message(FATAL_ERROR "${TARGET} has no compile options")
    endif()

    set(_required "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
    if (NOT "${_required}" IN_LIST _options)
        message(FATAL_ERROR "${TARGET} is missing compile option '${OPTION}'")
    endif()
endfunction()

function(_require_compile_option_after TARGET OPTION EARLIER_OPTION)
    get_target_property(_options "${TARGET}" COMPILE_OPTIONS)
    set(_required "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
    set(_earlier "$<$<COMPILE_LANGUAGE:CXX>:${EARLIER_OPTION}>")
    list(FIND _options "${_required}" _required_index)
    list(FIND _options "${_earlier}" _earlier_index)
    if ("${_required_index}" LESS_EQUAL "${_earlier_index}")
        message(FATAL_ERROR
            "${TARGET} compile option '${OPTION}' must follow '${EARLIER_OPTION}'")
    endif()
endfunction()

# Verify every managed compiled target receives the shared Canon policy.
get_property(_ipo_supported GLOBAL PROPERTY _CANON_IPO_SUPPORTED)
if (NOT _ipo_supported STREQUAL "YES" AND NOT _ipo_supported STREQUAL "NO")
    message(FATAL_ERROR "Canon IPO probe did not record a result: '${_ipo_supported}'")
endif()

set(_compiled_targets
    sample_static
    sample_shared
    sample_module
    sample_object
    warning_probe
    consumer
    sample_test
)

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
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
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(_warning_options
        -Weverything
        -Werror
    )
    set(_warning_suppressions
        -Wno-c++98-compat
        -Wno-c++98-compat-pedantic
        -Wno-c++20-compat
        -Wno-c++23-compat
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
    set(_warning_reenables
        -Wshadow-field-in-constructor-modified
    )
endif()

foreach(_target IN LISTS _compiled_targets)
    _require_target_property("${_target}" CXX_SCAN_FOR_MODULES FALSE)
    _require_target_property("${_target}" CXX_STANDARD 26)
    _require_target_property("${_target}" CXX_STANDARD_REQUIRED TRUE)
    _require_target_property("${_target}" POSITION_INDEPENDENT_CODE TRUE)
    _require_target_property("${_target}" VISIBILITY_INLINES_HIDDEN TRUE)
    _require_target_property("${_target}" CXX_VISIBILITY_PRESET hidden)

    if (CANON_ENABLE_WARNINGS)
        foreach(_option IN LISTS _warning_options _warning_suppressions _warning_reenables)
            _require_compile_option("${_target}" "${_option}")
        endforeach()
        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            _require_compile_option_after(
                "${_target}"
                -Wshadow-field-in-constructor-modified
                -Wno-shadow-field-in-constructor
            )
        endif()
    else()
        get_target_property(_options "${_target}" COMPILE_OPTIONS)
        foreach(_option IN LISTS _options)
            if (_option MATCHES ":-W")
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
    sample_test
)
foreach(_target IN LISTS _ipo_final_targets)
    if (_ipo_supported)
        _require_target_property("${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
    else()
        get_target_property(_ipo_property "${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE)
        if (NOT "${_ipo_property}" STREQUAL "_ipo_property-NOTFOUND")
            message(FATAL_ERROR
                "${_target} unexpectedly enables Release IPO when the toolchain does not support it")
        endif()
    endif()
endforeach()

foreach(_target IN ITEMS sample_static sample_object warning_probe)
    get_target_property(_ipo_property "${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE)
    if (NOT "${_ipo_property}" STREQUAL "_ipo_property-NOTFOUND")
        message(FATAL_ERROR "${_target} unexpectedly enables Release IPO")
    endif()
endforeach()

# Verify every managed library publishes its generated export header as a public file set.
foreach(_library IN ITEMS sample_static sample_shared sample_module)
    get_target_property(_header_sets "${_library}" INTERFACE_HEADER_SETS)
    if (NOT "canon_export_header" IN_LIST _header_sets)
        message(FATAL_ERROR
            "Canon export header for ${_library} is not a public HEADERS file set")
    endif()
endforeach()

_require_target_property(sample_static CXX_EXTENSIONS TRUE)
_require_target_property(sample_shared CXX_EXTENSIONS FALSE)
_require_target_property(sample_interface INTERFACE_COMPILE_DEFINITIONS CANON_SAMPLE_INTERFACE_VALUE=73)
_require_target_property(sample_interface INTERFACE_COMPILE_FEATURES cxx_std_17)

# Verify Canon does not leak build options through the unmanaged interface target.
foreach(_property IN ITEMS INTERFACE_COMPILE_OPTIONS INTERFACE_LINK_OPTIONS)
    get_target_property(_value sample_interface "${_property}")
    if (NOT "${_value}" STREQUAL "_value-NOTFOUND" AND NOT "${_value}" STREQUAL "")
        message(FATAL_ERROR
            "Canon policy leaked through sample_interface ${_property}: ${_value}")
    endif()
endforeach()

# Verify Canon does not modify the unmanaged external target.
get_target_property(_noisy_options noisy COMPILE_OPTIONS)
if (NOT "${_noisy_options}" STREQUAL "_noisy_options-NOTFOUND"
    AND NOT "${_noisy_options}" STREQUAL "")
    message(FATAL_ERROR "Canon policy leaked to unmanaged target noisy: ${_noisy_options}")
endif()
