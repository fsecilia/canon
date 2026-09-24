# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(CanonConsumer VERSION 0.1.0 LANGUAGES CXX)

if (NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
    message(FATAL_ERROR "CANON_SOURCE_DIR is required")
endif()

if (NOT COMMAND canon_apply_target)
    include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")
endif()

include(CTest)
add_subdirectory(external/noisy)

add_library(sample_static STATIC sample_static.cpp)
add_library(sample_shared SHARED sample_shared.cpp)
add_library(sample_module MODULE sample_module.cpp)
add_library(sample_object OBJECT sample_object.cpp)
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

# Apply Canon to each compiled library target under test.
foreach(_target IN ITEMS sample_static sample_shared sample_module sample_object)
    canon_apply_target("${_target}")
endforeach()

target_link_libraries(noisy PRIVATE sample_interface)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE sample_static sample_interface noisy)
canon_apply_target(consumer)

add_executable(sample_test sample_test.cpp)
target_link_libraries(sample_test PRIVATE sample_static)
canon_apply_target(sample_test)

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

# Verify every managed compiled target receives the shared Canon policy.
set(_compiled_targets
    sample_static
    sample_shared
    sample_module
    sample_object
    consumer
    sample_test
)
foreach(_target IN LISTS _compiled_targets)
    _require_target_property("${_target}" CXX_SCAN_FOR_MODULES FALSE)
    _require_target_property("${_target}" CXX_STANDARD 26)
    _require_target_property("${_target}" CXX_STANDARD_REQUIRED TRUE)
    _require_target_property("${_target}" INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
    _require_target_property("${_target}" POSITION_INDEPENDENT_CODE TRUE)
    _require_target_property("${_target}" VISIBILITY_INLINES_HIDDEN TRUE)
    _require_target_property("${_target}" CXX_VISIBILITY_PRESET hidden)
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
