# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(Canon VERSION 0.1.0 LANGUAGES NONE)

include(cmake/Canon.cmake)

# Keep Canon's development setup out of projects that vendor it as a subdirectory.
if (NOT PROJECT_IS_TOP_LEVEL)
    return()
endif()

include(CMakePackageConfigHelpers)
_canon_package_version_compatibility(_canon_version_compatibility)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY "${_canon_version_compatibility}"
    ARCH_INDEPENDENT
)

install(
    FILES
        cmake/Canon.cmake
        cmake/CanonConfig.cmake
        cmake/CanonCoverageClean.cmake
        cmake/CanonCoverageVerify.cmake
        "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    DESTINATION share/cmake/Canon
)

include(CTest)
if (NOT BUILD_TESTING)
    return()
endif()

enable_language(CXX)

find_package(Doxygen 1.9 QUIET OPTIONAL_COMPONENTS dot)
find_program(CANON_CLANG_TIDY_EXECUTABLE NAMES clang-tidy)

set(_canon_clang_tidy_supported FALSE)
if (CANON_CLANG_TIDY_EXECUTABLE)
    _canon_get_clang_tidy_version("${CANON_CLANG_TIDY_EXECUTABLE}" _canon_clang_tidy_version)
    if ("${_canon_clang_tidy_version}" STREQUAL "")
        message(WARNING
            "Canon clang-tidy validation unavailable: could not determine the version of "
            "'${CANON_CLANG_TIDY_EXECUTABLE}'")
    elseif ("${_canon_clang_tidy_version}" VERSION_LESS "${_CANON_MINIMUM_CLANG_TIDY_VERSION}")
        message(WARNING
            "Canon clang-tidy validation unavailable: clang-tidy ${_canon_clang_tidy_version} "
            "is older than the required minimum ${_CANON_MINIMUM_CLANG_TIDY_VERSION}")
    else()
        set(_canon_clang_tidy_supported TRUE)
    endif()
endif()

find_program(CANON_GCOVR_EXECUTABLE NAMES gcovr)
set(_canon_coverage_backend "")
set(_canon_coverage_disabled_reason "")
if (NOT CANON_GCOVR_EXECUTABLE)
    set(_canon_coverage_disabled_reason "gcovr was not found")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"
    OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
        AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU"))
    _canon_find_coverage_backend(_canon_coverage_backend)
    if ("${_canon_coverage_backend}" STREQUAL "")
        set(_canon_coverage_disabled_reason "no usable compiler-matched coverage backend was found")
    endif()
else()
    string(CONCAT _canon_coverage_disabled_reason
        "compiler '${CMAKE_CXX_COMPILER_ID}' with frontend "
        "'${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}' has no supported backend")
endif()

function(_canon_add_script_test NAME SCRIPT)
    add_test(
        NAME "canon.integration.${NAME}"
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DCANON_TEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/test/${NAME}"
            "-DCANON_GENERATOR=${CMAKE_GENERATOR}"
            "-DCANON_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            "-DCANON_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
            ${ARGN}
            -P "${CMAKE_CURRENT_SOURCE_DIR}/test/${SCRIPT}"
    )
    set_tests_properties("canon.integration.${NAME}" PROPERTIES LABELS integration TIMEOUT 120)
endfunction()

_canon_add_script_test(
    targets
    consumer/test.cmake
    -DCANON_BUILD_TYPE=Debug
)

_canon_add_script_test(
    targets.release
    consumer/test.cmake
    -DCANON_BUILD_TYPE=Release
)

_canon_add_script_test(
    executable.install
    executable-install/test.cmake
)

_canon_add_script_test(
    library.install
    library-install/test.cmake
)

_canon_add_script_test(
    package.config
    package-install/test.cmake
    -DCANON_TEST_CASE=config
)

_canon_add_script_test(
    package.version
    package-install/test.cmake
    -DCANON_TEST_CASE=version
)

_canon_add_script_test(
    package.dependencies
    package-install/test.cmake
    -DCANON_TEST_CASE=dependencies
)

_canon_add_script_test(
    targets.warnings
    consumer/test.cmake
    -DCANON_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
)

_canon_add_script_test(
    ipo.unavailable
    ipo-unavailable/test.cmake
)

_canon_add_script_test(
    tidy.version
    tooling/test.cmake
    -DCANON_TEST_CASE=version
)

_canon_add_script_test(
    asan
    asan/test.cmake
)

_canon_add_script_test(
    coverage.backend
    coverage/test.cmake
    -DCANON_TEST_CASE=backend
    "-DCANON_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}"
    "-DCANON_CXX_COMPILER_FRONTEND_VARIANT=${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}"
    "-DCANON_CXX_COMPILER_VERSION=${CMAKE_CXX_COMPILER_VERSION}"
)

_canon_add_script_test(
    coverage.override-error
    coverage/test.cmake
    -DCANON_TEST_CASE=override-error
    "-DCANON_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}"
)

set(_canon_coverage_test_arguments)
set(_canon_coverage_tests_enabled FALSE)
if (CANON_GCOVR_EXECUTABLE AND NOT "${_canon_coverage_backend}" STREQUAL "")
    set(_canon_coverage_tests_enabled TRUE)
    list(APPEND _canon_coverage_test_arguments
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}")
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        list(APPEND _canon_coverage_test_arguments
            "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        list(APPEND _canon_coverage_test_arguments
            "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
    endif()
endif()

_canon_add_script_test(
    coverage
    coverage/test.cmake
    -DCANON_TEST_CASE=consumer
    ${_canon_coverage_test_arguments}
)
_canon_add_script_test(
    coverage.empty-report
    coverage-empty/test.cmake
    ${_canon_coverage_test_arguments}
)
if (NOT _canon_coverage_tests_enabled)
    set_tests_properties(
        canon.integration.coverage
        canon.integration.coverage.empty-report
        PROPERTIES DISABLED TRUE
    )
    message(WARNING
        "Canon coverage tests are disabled: ${_canon_coverage_disabled_reason}\n"
        "  canon.integration.coverage\n"
        "  canon.integration.coverage.empty-report\n"
        "  canon.integration.presets.coverage")
endif()

_canon_add_script_test(
    tidy
    tooling/test.cmake
    -DCANON_TEST_CASE=consumer
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
if (NOT _canon_clang_tidy_supported)
    set_tests_properties(canon.integration.tidy PROPERTIES DISABLED TRUE)
    if (NOT CANON_CLANG_TIDY_EXECUTABLE)
        message(WARNING "Canon clang-tidy validation unavailable: clang-tidy was not found")
    endif()
endif()

_canon_add_script_test(
    documentation
    documentation/test.cmake
    -DCANON_TEST_CASE=consumer
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.install
    documentation/test.cmake
    -DCANON_TEST_CASE=install
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.policy
    documentation-policy/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.nested
    documentation-nested/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation-warning
    documentation-warning/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
if (NOT Doxygen_FOUND)
    set_tests_properties(
        canon.integration.documentation
        canon.integration.documentation.install
        canon.integration.documentation.policy
        canon.integration.documentation.nested
        canon.integration.documentation-warning
        PROPERTIES DISABLED TRUE
    )
    message(WARNING "Canon documentation validation unavailable: Doxygen 1.9 or newer was not found")
endif()

_canon_add_script_test(
    documentation-unavailable
    documentation-unavailable/test.cmake
)

_canon_add_script_test(
    vendored
    vendored/test.cmake
)

_canon_add_script_test(
    installed
    installed/test.cmake
    "-DCANON_EXPECTED_VERSION=${PROJECT_VERSION}"
)

_canon_add_script_test(
    presets.listings
    scripts/preset-listings.cmake
)

_canon_add_script_test(
    presets.debug
    scripts/preset-debug.cmake
)

_canon_add_script_test(
    presets.release
    scripts/preset-release.cmake
)

_canon_add_script_test(
    presets.asan
    scripts/preset-asan.cmake
)

_canon_add_script_test(
    presets.coverage
    scripts/preset-coverage.cmake
    ${_canon_coverage_test_arguments}
)
if (NOT _canon_coverage_tests_enabled)
    set_tests_properties(canon.integration.presets.coverage PROPERTIES DISABLED TRUE)
endif()

_canon_add_script_test(
    presets.tidy
    scripts/preset-tidy.cmake
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
if (NOT _canon_clang_tidy_supported)
    set_tests_properties(canon.integration.presets.tidy PROPERTIES DISABLED TRUE)
endif()

_canon_add_script_test(
    optional-tools.registration
    support/OptionalToolRegistration.cmake
    "-DCANON_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}"
    "-DCANON_TEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}"
    "-DCANON_EXPECT_COVERAGE_ENABLED=${_canon_coverage_tests_enabled}"
    "-DCANON_EXPECT_TIDY_ENABLED=${_canon_clang_tidy_supported}"
    "-DCANON_EXPECT_DOCUMENTATION_ENABLED=${Doxygen_FOUND}"
)

_canon_add_script_test(
    coverage.gcovr-unavailable
    coverage/test.cmake
    -DCANON_TEST_CASE=gcovr-unavailable
    "-DCANON_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}"
)

_canon_add_script_test(
    targets.missing
    target-errors/test.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=target 'missing' does not exist"
)

_canon_add_script_test(
    targets.interface
    target-errors/test.cmake
    -DCANON_TEST_CASE=interface
    "-DCANON_EXPECTED_ERROR=target 'sample_interface' has type"
    "-DCANON_EXPECTED_DETAIL='INTERFACE_LIBRARY'"
)

_canon_add_script_test(
    executables.missing
    executable-errors/test.cmake
    -DCANON_FIXTURE=missing
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): target 'missing' does not exist"
)

_canon_add_script_test(
    executables.library
    executable-errors/test.cmake
    -DCANON_FIXTURE=library
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): target 'sample' must be an executable"
)

_canon_add_script_test(
    executables.bundle
    executable-errors/test.cmake
    -DCANON_FIXTURE=bundle
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): MACOSX_BUNDLE target 'sample' is not supported"
)

_canon_add_script_test(
    libraries.missing
    library-errors/test.cmake
    -DCANON_FIXTURE=missing
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): target 'missing' does not exist"
)

_canon_add_script_test(
    libraries.executable
    library-errors/test.cmake
    -DCANON_FIXTURE=executable
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): target 'sample' must be a STATIC, SHARED, MODULE, or INTERFACE library"
)

_canon_add_script_test(
    libraries.object
    library-errors/test.cmake
    -DCANON_FIXTURE=object
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): target 'sample' must be a STATIC, SHARED, MODULE, or INTERFACE library"
)

_canon_add_script_test(
    libraries.framework
    library-errors/test.cmake
    -DCANON_FIXTURE=framework
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): FRAMEWORK target 'sample' is not supported"
)

_canon_add_script_test(
    dependencies.empty
    dependency-errors/test.cmake
    -DCANON_FIXTURE=empty
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): package name must not be empty"
)

_canon_add_script_test(
    dependencies.required
    dependency-errors/test.cmake
    -DCANON_FIXTURE=required
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): 'REQUIRED' is inherited"
)

_canon_add_script_test(
    dependencies.quiet
    dependency-errors/test.cmake
    -DCANON_FIXTURE=quiet
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): 'QUIET' is inherited"
)

_canon_add_script_test(
    dependencies.no-package
    dependency-errors/test.cmake
    -DCANON_FIXTURE=no-package
    "-DCANON_EXPECTED_ERROR=package dependencies were declared, but project"
)
