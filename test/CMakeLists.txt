# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

enable_language(CXX)
include(CMakePackageConfigHelpers)

set(_canon_test_spec_dir "${CMAKE_CURRENT_BINARY_DIR}/specs")

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_canon_compiler_profile gcc)
    set(_canon_coverage_override CANON_GCOV_EXECUTABLE)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU")
    set(_canon_compiler_profile clang)
    set(_canon_coverage_override CANON_LLVM_COV_EXECUTABLE)
else()
    message(FATAL_ERROR
        "Canon integration tests require GCC or Clang with the GNU frontend; got '${CMAKE_CXX_COMPILER_ID}' with "
        "frontend '${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}'")
endif()

#
# Optional tools
#

# Each optional tool either becomes available to fixtures or records why the tests that require it are disabled.
set(_canon_tool_arguments)

find_program(CANON_CLANG_TIDY_EXECUTABLE NAMES clang-tidy)
if(NOT CANON_CLANG_TIDY_EXECUTABLE)
    set(_canon_missing_tidy "clang-tidy was not found")
else()
    _canon_get_clang_tidy_version("${CANON_CLANG_TIDY_EXECUTABLE}" _canon_tidy_version)
    if("${_canon_tidy_version}" VERSION_LESS 21.1.6)
        set(_canon_missing_tidy "'${CANON_CLANG_TIDY_EXECUTABLE}' reports version '${_canon_tidy_version}'; 21.1.6 is required")
    else()
        list(APPEND _canon_tool_arguments "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}")
    endif()
endif()

find_program(CANON_GCOVR_EXECUTABLE NAMES gcovr)
if(NOT CANON_GCOVR_EXECUTABLE)
    set(_canon_missing_coverage "gcovr was not found")
else()
    _canon_find_coverage_backend(_canon_coverage_backend _canon_missing_coverage)
    if(NOT "${_canon_coverage_backend}" STREQUAL "")
        list(APPEND _canon_tool_arguments "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}")
        if(NOT "${${_canon_coverage_override}}" STREQUAL "")
            list(APPEND _canon_tool_arguments "-D${_canon_coverage_override}=${${_canon_coverage_override}}")
        endif()
    endif()
endif()

find_package(Doxygen 1.9 QUIET OPTIONAL_COMPONENTS dot)
if(NOT Doxygen_FOUND)
    set(_canon_missing_doxygen "Doxygen 1.9 or newer was not found")
else()
    list(APPEND _canon_tool_arguments "-DDOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}")
endif()

if(NOT EXISTS "${PROJECT_SOURCE_DIR}/external/googletest/CMakeLists.txt")
    set(_canon_missing_googletest "initialize submodule 'external/googletest'")
endif()

#
# Test registration
#

# Appends set(NAME values...) to the CMake code in TEXT_VARIABLE, preserving each value literally.
function(_canon_append_set TEXT_VARIABLE NAME)
    cmake_parse_arguments(PARSE_ARGV 2 _value "" "" "")
    set(_text "${${TEXT_VARIABLE}}set(${NAME}")
    foreach(_value IN LISTS _value_UNPARSED_ARGUMENTS)
        string(APPEND _text " [==[${_value}]==]")
    endforeach()
    set(${TEXT_VARIABLE} "${_text})\n" PARENT_SCOPE)
endfunction()

set(_canon_common_spec "cmake_minimum_required(VERSION 3.31.6)\n")
_canon_append_set(_canon_common_spec CANON_SOURCE_DIR "${PROJECT_SOURCE_DIR}")
_canon_append_set(_canon_common_spec CANON_GENERATOR "${CMAKE_GENERATOR}")
_canon_append_set(_canon_common_spec CANON_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
_canon_append_set(_canon_common_spec CANON_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")
_canon_append_set(_canon_common_spec CANON_EXECUTABLE_SUFFIX "${CMAKE_EXECUTABLE_SUFFIX}")
_canon_append_set(_canon_common_spec CANON_TEST_TOOL_ARGUMENTS ${_canon_tool_arguments})
file(WRITE "${_canon_test_spec_dir}/common.cmake" "${_canon_common_spec}")

# Registers one integration test.
#
# By default the test runs support/fixture.cmake against FIXTURE, a directory below test/. CASE supplies CMake code
# that the fixture runs after loading Canon; a CASE without a FIXTURE runs in the minimal support/case project. SCRIPT
# replaces the generic driver with a test-specific one. ARGS are passed to every fixture configure in the test, and
# DEFINES (NAME=VALUE) are set before the driver runs.
#
# A test that REQUIRES an unavailable optional tool is registered disabled and reported once per tool at the end of
# configuration.
function(_canon_add_test NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        _test
        "EXPECT_FAILURE;BUILD;INSTALL;LONG_PATH"
        "SCRIPT;FIXTURE;CASE;CONFIG;INSTALL_TARGET"
        "ARGS;DEFINES;EXPECTED_OUTPUT;REQUIRES"
    )
    if(_test_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "_canon_add_test(${NAME}): unexpected arguments: ${_test_UNPARSED_ARGUMENTS}")
    endif()
    if("${_test_SCRIPT}" STREQUAL "")
        set(_test_SCRIPT support/fixture.cmake)
    endif()
    if("${_test_FIXTURE}" STREQUAL "" AND DEFINED _test_CASE)
        set(_test_FIXTURE support/case)
    endif()
    if("${_test_CONFIG}" STREQUAL "")
        set(_test_CONFIG Debug)
    endif()

    set(_spec "include([==[${_canon_test_spec_dir}/common.cmake]==])\n")
    _canon_append_set(_spec CANON_TEST_NAME "${NAME}")
    _canon_append_set(_spec CANON_TEST_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")
    _canon_append_set(_spec CANON_TEST_CONFIG "${_test_CONFIG}")
    _canon_append_set(_spec CANON_TEST_CONFIGURE_ARGUMENTS ${_test_ARGS})
    _canon_append_set(_spec CANON_TEST_EXPECTED_OUTPUT ${_test_EXPECTED_OUTPUT})
    foreach(_option IN ITEMS EXPECT_FAILURE BUILD INSTALL LONG_PATH)
        _canon_append_set(_spec "CANON_TEST_${_option}" "${_test_${_option}}")
    endforeach()
    _canon_append_set(_spec CANON_TEST_INSTALL_TARGET "${_test_INSTALL_TARGET}")
    if(NOT "${_test_FIXTURE}" STREQUAL "")
        _canon_append_set(_spec CANON_TEST_FIXTURE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${_test_FIXTURE}")
    endif()
    set(_case_file "")
    if(DEFINED _test_CASE)
        set(_case_file "${_canon_test_spec_dir}/${NAME}.case.cmake")
        file(WRITE "${_case_file}" "${_test_CASE}\n")
    endif()
    _canon_append_set(_spec CANON_TEST_CASE_FILE "${_case_file}")
    foreach(_definition IN LISTS _test_DEFINES)
        string(REGEX MATCH "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$" _matched "${_definition}")
        if("${_matched}" STREQUAL "")
            message(FATAL_ERROR "_canon_add_test(${NAME}): DEFINES entry '${_definition}' is not NAME=VALUE")
        endif()
        _canon_append_set(_spec "${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
    endforeach()
    string(APPEND _spec "include([==[${CMAKE_CURRENT_SOURCE_DIR}/${_test_SCRIPT}]==])\n")

    set(_spec_file "${_canon_test_spec_dir}/${NAME}.cmake")
    file(WRITE "${_spec_file}" "${_spec}")

    set(_test_name "canon.integration.${NAME}")
    add_test(NAME "${_test_name}" COMMAND "${CMAKE_COMMAND}" -P "${_spec_file}")
    set_tests_properties("${_test_name}" PROPERTIES LABELS integration TIMEOUT 180)

    foreach(_requirement IN LISTS _test_REQUIRES)
        if(NOT "${_canon_missing_${_requirement}}" STREQUAL "")
            set_tests_properties("${_test_name}" PROPERTIES DISABLED TRUE)
            set_property(GLOBAL APPEND PROPERTY "_CANON_DISABLED_${_requirement}" "${_test_name}")
        endif()
    endforeach()
endfunction()

#
# Compiled-target and library policy
#

foreach(_canon_variant IN ITEMS "targets;Debug;" "targets.release;Release;" "targets.warnings;Debug;-DCANON_ENABLE_WARNINGS=ON")
    list(GET _canon_variant 0 _canon_name)
    list(GET _canon_variant 1 _canon_config)
    list(GET _canon_variant 2 _canon_arguments)
    _canon_add_test("${_canon_name}" SCRIPT consumer/test.cmake CONFIG "${_canon_config}" ARGS ${_canon_arguments})
endforeach()

_canon_add_test(idempotence FIXTURE idempotence ARGS -DCANON_ENABLE_WARNINGS=ON)
_canon_add_test(cmake.policy FIXTURE policy)
_canon_add_test(
    ipo.unavailable
    FIXTURE ipo
    CONFIG Release
    BUILD
    EXPECTED_OUTPUT "Canon: IPO is unavailable; Release builds will continue without it"
)

_canon_add_test(
    targets.arguments
    CASE [[
        add_library(sample STATIC sample.cpp)
        canon_apply_target(sample unexpected)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_apply_target(): expected exactly one target"
)
_canon_add_test(
    targets.missing
    CASE [[canon_apply_target(missing)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_apply_target(): target 'missing' does not exist"
)
_canon_add_test(
    targets.interface
    CASE [[
        add_library(sample_interface INTERFACE)
        canon_apply_target(sample_interface)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "target 'sample_interface' has type 'INTERFACE_LIBRARY'"
)
_canon_add_test(
    libraries.arguments
    CASE [[
        add_library(sample INTERFACE)
        canon_apply_library(sample unexpected)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_apply_library(): expected exactly one target"
)
_canon_add_test(
    libraries.missing
    CASE [[canon_apply_library(missing)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_apply_library(): target 'missing' does not exist"
)
_canon_add_test(
    libraries.object
    CASE [[
        add_library(sample OBJECT IMPORTED)
        canon_apply_library(sample)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_apply_library(): target 'sample' must be a STATIC, SHARED, MODULE, or INTERFACE library"
)

#
# Export headers
#

_canon_add_test(
    export-header.macro-collision
    CASE [[
        add_library(first SHARED sample.cpp)
        add_library(second SHARED sample.cpp)
        canon_generate_export_header(first first/export.hpp SHARED_API)
        canon_generate_export_header(second second/export.hpp SHARED_API)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_generate_export_header(): macro 'SHARED_API' is already used by target 'first'"
)
_canon_add_test(
    export-header.header-collision
    CASE [[
        add_library(first SHARED sample.cpp)
        add_library(second SHARED sample.cpp)
        canon_generate_export_header(first shared/export.hpp FIRST_API)
        canon_generate_export_header(second shared/export.hpp SECOND_API)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "canon_generate_export_header(): header 'shared/export.hpp' is already generated by target 'first' with macro 'FIRST_API'"
)
_canon_add_test(
    export-header.outside
    CASE [[
        add_library(sample SHARED sample.cpp)
        canon_generate_export_header(sample ../escaped.hpp SAMPLE_API)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "canon_generate_export_header(): HEADER '../escaped.hpp' must resolve beneath target 'sample' generated directory"
)

#
# Dependencies
#

set(_canon_dependency_package "-DDependencyFixture_DIR=${CMAKE_CURRENT_BINARY_DIR}/packages/DependencyFixture")
configure_file(
    dependency/package/DependencyFixtureConfig.cmake
    packages/DependencyFixture/DependencyFixtureConfig.cmake
    COPYONLY
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/packages/DependencyFixture/DependencyFixtureConfigVersion.cmake"
    VERSION 7.6.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

_canon_add_test(
    dependencies.resolve.vendored
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(
            runtime
            PACKAGE DependencyFixture
            VERSION "7.3...<8.0"
            TARGETS DependencyFixture::Runtime DependencyFixture::Support
        )
        get_target_property(_system fixture_runtime SYSTEM)
        if(NOT _system)
            message(FATAL_ERROR "vendored dependency targets must be SYSTEM so their headers stay quiet")
        endif()
    ]]
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using vendored 'runtime'"
)
_canon_add_test(
    dependencies.resolve.installed
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(
            packaged
            PACKAGE DependencyFixture
            VERSION "7.3...<8.0"
            TARGETS DependencyFixture::Core DependencyFixture::Support
        )
    ]]
    ARGS "${_canon_dependency_package}"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using installed package 'DependencyFixture'"
)
_canon_add_test(
    dependencies.resolve.provided
    FIXTURE dependency
    CASE [[
        add_library(DependencyFixture::Core INTERFACE IMPORTED GLOBAL)
        add_library(DependencyFixture::Support INTERFACE IMPORTED GLOBAL)
        canon_resolve_dependency(
            poisoned
            PACKAGE DependencyFixture
            VERSION "7.3...<8.0"
            TARGETS DependencyFixture::Core DependencyFixture::Support
        )
    ]]
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - already provided"
)
_canon_add_test(
    dependencies.resolve.module
    FIXTURE dependency
    CASE [[
        list(PREPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
        canon_resolve_dependency(vulkan-fixture PACKAGE VulkanFixture VERSION 7.3 TARGETS VulkanFixture::Vulkan)
    ]]
    EXPECTED_OUTPUT "finding dependency 'VulkanFixture' - using installed package 'VulkanFixture'"
)
_canon_add_test(
    dependencies.resolve.siblings
    FIXTURE dependency
    CASE [[
        add_subdirectory(sibling sibling-first)
        add_subdirectory(sibling sibling-second)
    ]]
    ARGS "${_canon_dependency_package}"
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - already resolved using installed provider"
)

_canon_add_test(
    dependencies.resolve.empty
    FIXTURE dependency
    CASE [[canon_resolve_dependency("" PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Core)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_resolve_dependency(): external name must not be empty"
)
_canon_add_test(
    dependencies.resolve.outside
    FIXTURE dependency
    CASE [[canon_resolve_dependency(../app PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Core)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "canon_resolve_dependency(): external name '../app' must identify a path beneath the project's external directory"
)
_canon_add_test(
    dependencies.resolve.version
    FIXTURE dependency
    CASE [[canon_resolve_dependency(runtime PACKAGE DependencyFixture TARGETS DependencyFixture::Runtime)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_resolve_dependency(): VERSION is required"
)
_canon_add_test(
    dependencies.resolve.targets
    FIXTURE dependency
    CASE [[canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0")]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_resolve_dependency(): TARGETS is required"
)
_canon_add_test(
    dependencies.resolve.partial
    FIXTURE dependency
    CASE [[
        add_library(DependencyFixture::Core INTERFACE IMPORTED)
        canon_resolve_dependency(
            runtime
            PACKAGE DependencyFixture
            VERSION "7.3...<8.0"
            TARGETS DependencyFixture::Core DependencyFixture::Support
        )
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "finding dependency 'DependencyFixture' - partially provided"
        "dependency 'DependencyFixture' is only partially available"
        "present targets: DependencyFixture::Core; missing targets: DependencyFixture::Support"
)
_canon_add_test(
    dependencies.resolve.provider-first
    FIXTURE dependency
    CASE [[
        add_library(DependencyFixture::Core INTERFACE IMPORTED GLOBAL)
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Core)
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Support)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "finding dependency 'DependencyFixture' - already resolved"
        "dependency 'runtime' was already resolved using provider 'provided'"
        "missing required targets: DependencyFixture::Support"
)
_canon_add_test(
    dependencies.resolve.nested-provider-first
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(mid PACKAGE MidFixture VERSION "7.3...<8.0" TARGETS MidFixture::Core)
        canon_resolve_dependency(leaf PACKAGE LeafFixture VERSION "7.3...<8.0" TARGETS LeafFixture::Support)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "finding dependency 'LeafFixture' - already resolved"
        "dependency 'leaf' was already resolved using provider 'vendored'"
        "missing required targets: LeafFixture::Support"
)
_canon_add_test(
    dependencies.resolve.missing
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(
            missing-dependency
            PACKAGE CanonMissingDependencyFixture
            VERSION "7.3...<8.0"
            TARGETS CanonMissingDependencyFixture::Core
        )
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "finding dependency 'CanonMissingDependencyFixture' - unavailable"
        "dependency 'CanonMissingDependencyFixture' version '7.3...<8.0' is unavailable"
        "initialize vendored dependency 'external/missing-dependency', or install a compatible package"
)

_canon_add_test(
    dependencies.install.vendored
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        canon_install_dependency(runtime TARGETS DependencyFixture::Runtime DependencyFixture::Support)
        canon_install_dependency(runtime TARGETS DependencyFixture::Runtime)

        add_executable(app main.cpp)
        target_link_libraries(app PRIVATE DependencyFixture::Runtime)
        canon_apply_target(app)

        canon_fixture_expect_installed(
            PRESENT_TARGETS fixture_runtime fixture_support
            ABSENT_TARGETS fixture_decoy
            ABSENT_NAMELINKS fixture_runtime
            ABSENT forbidden/forbidden.txt
        )
    ]]
    BUILD
    INSTALL
    EXPECTED_OUTPUT "finding dependency 'DependencyFixture' - using vendored 'runtime'"
)
# The vendored runtime is EXCLUDE_FROM_ALL and nothing links it, so only Canon's build dependency builds it.
_canon_add_test(
    dependencies.install.build
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        canon_install_dependency(runtime TARGETS DependencyFixture::Runtime)
        canon_test_require_target_property(fixture_runtime EXCLUDE_FROM_ALL TRUE)
        canon_fixture_expect_installed(PRESENT_TARGETS fixture_runtime)
    ]]
    LONG_PATH
    BUILD
    INSTALL
)
_canon_add_test(
    dependencies.install.subdirectory
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        add_subdirectory(app)
        canon_fixture_expect_installed(PRESENT_TARGETS fixture_runtime ABSENT_TARGETS fixture_decoy)
    ]]
    INSTALL_TARGET app/install
)
_canon_add_test(
    dependencies.install.nested
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(mid PACKAGE MidFixture VERSION "7.3...<8.0" TARGETS MidFixture::Core)
        canon_resolve_dependency(leaf PACKAGE LeafFixture VERSION "7.3...<8.0" TARGETS LeafFixture::Runtime)
        canon_install_dependency(leaf TARGETS LeafFixture::Runtime)
        canon_fixture_expect_installed(PRESENT_TARGETS leaf_runtime)
    ]]
    BUILD
    INSTALL
    EXPECTED_OUTPUT
        "finding dependency 'LeafFixture' - using vendored 'leaf'"
        "finding dependency 'LeafFixture' - already resolved using vendored provider"
)
_canon_add_test(
    dependencies.install.installed
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(
            packaged
            PACKAGE DependencyFixture
            VERSION "7.3...<8.0"
            TARGETS DependencyFixture::Core DependencyFixture::Support
        )
        canon_install_dependency(packaged TARGETS DependencyFixture::Core)
    ]]
    ARGS "${_canon_dependency_package}"
)
_canon_add_test(
    dependencies.install.provided
    FIXTURE dependency
    CASE [[
        add_library(DependencyFixture::Core INTERFACE IMPORTED GLOBAL)
        canon_resolve_dependency(poisoned PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Core)
        canon_install_dependency(poisoned TARGETS DependencyFixture::Core)
    ]]
)

_canon_add_test(
    dependencies.install.empty
    FIXTURE dependency
    CASE [[canon_install_dependency("" TARGETS Missing::Target)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): external name must not be empty"
)
_canon_add_test(
    dependencies.install.targets
    FIXTURE dependency
    CASE [[canon_install_dependency(runtime)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): TARGETS is required"
)
_canon_add_test(
    dependencies.install.unresolved
    FIXTURE dependency
    CASE [[canon_install_dependency(runtime TARGETS Missing::Target)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): dependency 'runtime' has not been resolved"
)
_canon_add_test(
    dependencies.install.missing
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        canon_install_dependency(runtime TARGETS DependencyFixture::Missing)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): target 'DependencyFixture::Missing' does not exist"
)
_canon_add_test(
    dependencies.install.missing-provided
    FIXTURE dependency
    CASE [[
        add_library(DependencyFixture::Runtime INTERFACE IMPORTED GLOBAL)
        canon_resolve_dependency(poisoned PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        canon_install_dependency(poisoned TARGETS DependencyFixture::Missing)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): target 'DependencyFixture::Missing' does not exist"
)
_canon_add_test(
    dependencies.install.foreign
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(runtime PACKAGE DependencyFixture VERSION "7.3...<8.0" TARGETS DependencyFixture::Runtime)
        add_library(foreign SHARED sample.cpp)
        canon_install_dependency(runtime TARGETS foreign)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): target 'foreign' was not created by vendored dependency 'runtime'"
)
_canon_add_test(
    dependencies.install.nested-foreign
    FIXTURE dependency
    CASE [[
        canon_resolve_dependency(mid PACKAGE MidFixture VERSION "7.3...<8.0" TARGETS MidFixture::Core)
        canon_install_dependency(mid TARGETS LeafFixture::Runtime)
    ]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_install_dependency(): target 'LeafFixture::Runtime' was not created by vendored dependency 'mid'"
)
foreach(_canon_variant IN ITEMS
    "static;must be a SHARED library"
    "imported;is imported and cannot be installed as vendored runtime"
    "framework;is not supported"
)
    list(GET _canon_variant 0 _canon_kind)
    list(GET _canon_variant 1 _canon_error)
    _canon_add_test(
        "dependencies.install.${_canon_kind}"
        FIXTURE dependency
        CASE "
            canon_resolve_dependency(
                ${_canon_kind}-runtime
                PACKAGE DependencyFixture
                VERSION 7.3
                TARGETS DependencyFixture::Runtime
            )
            canon_install_dependency(${_canon_kind}-runtime TARGETS DependencyFixture::Runtime)
        "
        EXPECT_FAILURE
        EXPECTED_OUTPUT "target 'DependencyFixture::Runtime' ${_canon_error}"
    )
endforeach()

#
# GoogleTest
#

configure_file(googletest/GTestConfig.cmake packages/GTest/GTestConfig.cmake COPYONLY)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/packages/GTest/GTestConfigVersion.cmake"
    VERSION 1.18.0
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

_canon_add_test(
    googletest.vendored
    FIXTURE googletest/vendored
    INSTALL
    EXPECTED_OUTPUT "finding dependency 'GTest' - using vendored 'googletest'"
    REQUIRES googletest
)
_canon_add_test(
    googletest.nested
    FIXTURE googletest/nested
    EXPECTED_OUTPUT
        "finding dependency 'GTest' - using vendored 'googletest'"
        "finding dependency 'GTest' - already resolved using vendored provider"
    REQUIRES googletest
)
_canon_add_test(
    googletest.provided
    CASE [[
        add_library(GTest::gmock_main INTERFACE IMPORTED GLOBAL)
        add_library(GTest::gtest_main INTERFACE IMPORTED GLOBAL)
        canon_require_googletest()
    ]]
    EXPECTED_OUTPUT "finding dependency 'GTest' - already provided"
)
_canon_add_test(
    googletest.arguments
    CASE [[canon_require_googletest(unexpected)]]
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_require_googletest(): does not accept arguments"
)

#
# Packaging and consumption
#

_canon_add_test(application SCRIPT application/test.cmake ARGS -DCANON_ENABLE_WARNINGS=ON)
_canon_add_test(vendored FIXTURE vendored BUILD INSTALL)
_canon_add_test(
    installed
    SCRIPT installed/test.cmake
    DEFINES
        "CANON_EXPECTED_VERSION=${PROJECT_VERSION}"
        "CANON_GTEST_PACKAGE_DIR=${CMAKE_CURRENT_BINARY_DIR}/packages/GTest"
)

#
# AddressSanitizer
#

_canon_add_test(asan SCRIPT asan/test.cmake ARGS -DCANON_ENABLE_ASAN=ON)
_canon_add_test(
    asan.unsupported
    CASE [[
        set(CMAKE_CXX_COMPILER_ID Clang)
        set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT MSVC)
        add_library(sample STATIC sample.cpp)
        canon_apply_target(sample)
    ]]
    ARGS -DCANON_ENABLE_ASAN=ON
    EXPECT_FAILURE
    EXPECTED_OUTPUT "Canon ASan is not supported for compiler 'Clang' with frontend 'MSVC'"
)

#
# Coverage
#

_canon_add_test(
    coverage.backend
    SCRIPT coverage/backend.cmake
    DEFINES
        "CANON_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}"
        "CANON_CXX_COMPILER_FRONTEND_VARIANT=${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}"
        "CANON_CXX_COMPILER_VERSION=${CMAKE_CXX_COMPILER_VERSION}"
)
_canon_add_test(
    coverage.backend-required
    SCRIPT coverage/backend-required.cmake
    DEFINES "CANON_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}"
)
_canon_add_test(
    coverage.override-error
    FIXTURE coverage/project
    ARGS -DCANON_ENABLE_COVERAGE=ON "-D${_canon_coverage_override}=${CMAKE_COMMAND}"
    EXPECT_FAILURE
    EXPECTED_OUTPUT
        "Canon coverage reporting is unavailable: coverage override ${_canon_coverage_override}='${CMAKE_COMMAND}' is invalid:"
)
_canon_add_test(coverage SCRIPT coverage/consumer.cmake ARGS -DCANON_ENABLE_COVERAGE=ON REQUIRES coverage)
_canon_add_test(
    coverage.tidy
    SCRIPT coverage/consumer.cmake
    ARGS -DCANON_ENABLE_COVERAGE=ON -DCANON_ENABLE_TIDY=ON
    REQUIRES coverage tidy
)
_canon_add_test(coverage.nested SCRIPT coverage/nested.cmake ARGS -DCANON_ENABLE_COVERAGE=ON REQUIRES coverage)
_canon_add_test(coverage.empty-report SCRIPT coverage/empty.cmake ARGS -DCANON_ENABLE_COVERAGE=ON REQUIRES coverage)

#
# clang-tidy
#

_canon_add_test(
    tidy
    SCRIPT tooling/consumer.cmake
    ARGS -DCANON_ENABLE_WARNINGS=ON -DCANON_ENABLE_TIDY=ON
    REQUIRES tidy
)
_canon_add_test(
    tidy.symlink
    SCRIPT tooling/symlink.cmake
    ARGS -DCANON_ENABLE_WARNINGS=ON -DCANON_ENABLE_TIDY=ON
    REQUIRES tidy
)
# CMake itself is a deterministic executable whose reported version is below the clang-tidy floor.
_canon_add_test(
    tidy.version
    FIXTURE tooling/vendored
    ARGS -DCANON_ENABLE_TIDY=ON "-DCANON_CLANG_TIDY_EXECUTABLE=${CMAKE_COMMAND}"
    EXPECT_FAILURE
    EXPECTED_OUTPUT "Canon requires clang-tidy 21.1.6 or newer"
)
_canon_add_test(
    tidy.validation-cache
    FIXTURE tooling
    ARGS -DCANON_ENABLE_TIDY=ON "-DCANON_SECOND_CLANG_TIDY_EXECUTABLE=${CMAKE_COMMAND}"
    EXPECT_FAILURE
    EXPECTED_OUTPUT "Canon requires clang-tidy 21.1.6 or newer"
    REQUIRES tidy
)

#
# Documentation
#

foreach(_canon_documentation_test IN ITEMS consumer install in-source policy no-main-page nested warning)
    _canon_add_test(
        "documentation.${_canon_documentation_test}"
        SCRIPT "documentation/${_canon_documentation_test}.cmake"
        REQUIRES doxygen
    )
endforeach()
_canon_add_test(documentation.unavailable SCRIPT documentation/unavailable.cmake)
_canon_add_test(
    documentation.main-page-missing
    FIXTURE documentation/project
    ARGS -DDOXYGEN_USE_MDFILE_AS_MAINPAGE=MISSING.md
    EXPECT_FAILURE
    EXPECTED_OUTPUT "canon_add_documentation(): main page 'MISSING.md' does not exist"
)

#
# Shared presets
#

foreach(_canon_intent IN ITEMS debug release rel-with-deb-info asan tidy coverage)
    set(_canon_requirements)
    if("${_canon_intent}" STREQUAL "tidy" OR "${_canon_intent}" STREQUAL "coverage")
        set(_canon_requirements "${_canon_intent}")
    endif()
    _canon_add_test(
        "presets.${_canon_compiler_profile}.${_canon_intent}"
        SCRIPT presets/test.cmake
        DEFINES "CANON_PRESET_PROFILE=${_canon_compiler_profile}" "CANON_PRESET_INTENT=${_canon_intent}"
        REQUIRES ${_canon_requirements}
    )
endforeach()

#
# Reduced coverage report
#

foreach(_canon_requirement IN ITEMS tidy coverage doxygen googletest)
    get_property(_canon_disabled GLOBAL PROPERTY "_CANON_DISABLED_${_canon_requirement}")
    if(_canon_disabled)
        list(JOIN _canon_disabled "\n  " _canon_disabled_text)
        message(WARNING
            "Canon ${_canon_requirement} validation unavailable: ${_canon_missing_${_canon_requirement}}\n"
            "Disabled tests:\n  ${_canon_disabled_text}")
    endif()
endforeach()
