# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

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
            "-DCANON_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
            "-DCANON_TEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
            "-DCANON_GENERATOR=${CMAKE_GENERATOR}"
            "-DCANON_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            "-DCANON_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
            ${ARGN}
            -P "${CMAKE_CURRENT_SOURCE_DIR}/${SCRIPT}"
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
    executable/install/test.cmake
)

_canon_add_script_test(
    library.install
    library/install/test.cmake
)

_canon_add_script_test(
    package.config
    package/install/config.cmake
)

_canon_add_script_test(
    package.version
    package/install/version.cmake
)

_canon_add_script_test(
    package.dependencies
    package/install/dependencies.cmake
)

_canon_add_script_test(
    targets.warnings
    consumer/test.cmake
    -DCANON_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
)

_canon_add_script_test(
    ipo.unavailable
    ipo/unavailable/test.cmake
)

_canon_add_script_test(
    tidy.version
    tooling/version.cmake
)

_canon_add_script_test(
    tidy.validation-cache
    tooling/validation-cache.cmake
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)

_canon_add_script_test(
    asan
    asan/test.cmake
)

_canon_add_script_test(
    asan.unsupported
    target/errors/test.cmake
    -DCANON_TEST_CASE=asan-unsupported
    "-DCANON_EXPECTED_ERROR=Canon ASan does not support compiler 'Clang'"
    "-DCANON_EXPECTED_DETAIL=with frontend 'MSVC'"
)

_canon_add_script_test(
    coverage.backend
    coverage/backend.cmake
    "-DCANON_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}"
    "-DCANON_CXX_COMPILER_FRONTEND_VARIANT=${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}"
    "-DCANON_CXX_COMPILER_VERSION=${CMAKE_CXX_COMPILER_VERSION}"
)

_canon_add_script_test(
    coverage.override-error
    coverage/override-error.cmake
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
    coverage/consumer.cmake
    ${_canon_coverage_test_arguments}
)
_canon_add_script_test(
    coverage.nested
    coverage/nested.cmake
    ${_canon_coverage_test_arguments}
)
_canon_add_script_test(
    coverage.empty-report
    coverage/empty/test.cmake
    ${_canon_coverage_test_arguments}
)
if (NOT _canon_coverage_tests_enabled)
    set_tests_properties(
        canon.integration.coverage
        canon.integration.coverage.nested
        canon.integration.coverage.empty-report
        PROPERTIES DISABLED TRUE
    )
    message(WARNING
        "Canon coverage tests are disabled: ${_canon_coverage_disabled_reason}\n"
        "  canon.integration.coverage\n"
        "  canon.integration.coverage.nested\n"
        "  canon.integration.coverage.empty-report\n"
        "  canon.integration.presets.coverage")
endif()

_canon_add_script_test(
    tidy
    tooling/consumer.cmake
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
if (NOT _canon_clang_tidy_supported)
    set_tests_properties(
        canon.integration.tidy
        canon.integration.tidy.validation-cache
        PROPERTIES DISABLED TRUE
    )
    if (NOT CANON_CLANG_TIDY_EXECUTABLE)
        message(WARNING "Canon clang-tidy validation unavailable: clang-tidy was not found")
    endif()
endif()

_canon_add_script_test(
    documentation
    documentation/consumer.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.install
    documentation/install.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.policy
    documentation/policy/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.nested
    documentation/nested/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
_canon_add_script_test(
    documentation.warning
    documentation/warning/test.cmake
    "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
)
if (NOT Doxygen_FOUND)
    set_tests_properties(
        canon.integration.documentation
        canon.integration.documentation.install
        canon.integration.documentation.policy
        canon.integration.documentation.nested
        canon.integration.documentation.warning
        PROPERTIES DISABLED TRUE
    )
    message(WARNING "Canon documentation validation unavailable: Doxygen 1.9 or newer was not found")
endif()

_canon_add_script_test(
    documentation.unavailable
    documentation/unavailable/test.cmake
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
    presets.debug
    presets/debug.cmake
)

_canon_add_script_test(
    presets.release
    presets/release.cmake
)

_canon_add_script_test(
    presets.asan
    presets/asan.cmake
)

_canon_add_script_test(
    presets.coverage
    presets/coverage.cmake
    ${_canon_coverage_test_arguments}
)
if (NOT _canon_coverage_tests_enabled)
    set_tests_properties(canon.integration.presets.coverage PROPERTIES DISABLED TRUE)
endif()

_canon_add_script_test(
    presets.tidy
    presets/tidy.cmake
    "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
)
if (NOT _canon_clang_tidy_supported)
    set_tests_properties(canon.integration.presets.tidy PROPERTIES DISABLED TRUE)
endif()

_canon_add_script_test(
    targets.missing
    target/errors/test.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=target 'missing' does not exist"
)

_canon_add_script_test(
    targets.interface
    target/errors/test.cmake
    -DCANON_TEST_CASE=interface
    "-DCANON_EXPECTED_ERROR=target 'sample_interface' has type"
    "-DCANON_EXPECTED_DETAIL='INTERFACE_LIBRARY'"
)

_canon_add_script_test(
    executables.missing
    executable/errors/test.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): target 'missing' does not exist"
)

_canon_add_script_test(
    executables.library
    executable/errors/test.cmake
    -DCANON_TEST_CASE=library
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): target 'sample' must be an executable"
)

_canon_add_script_test(
    executables.bundle
    executable/errors/test.cmake
    -DCANON_TEST_CASE=bundle
    "-DCANON_EXPECTED_ERROR=canon_apply_executable(): MACOSX_BUNDLE target 'sample' is not supported"
)

_canon_add_script_test(
    libraries.missing
    library/errors/test.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): target 'missing' does not exist"
)

_canon_add_script_test(
    libraries.object
    library/errors/test.cmake
    -DCANON_TEST_CASE=object
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): target 'sample' must be a STATIC, SHARED, MODULE, or INTERFACE library"
)

_canon_add_script_test(
    libraries.framework
    library/errors/test.cmake
    -DCANON_TEST_CASE=framework
    "-DCANON_EXPECTED_ERROR=canon_apply_library(): FRAMEWORK target 'sample' is not supported"
)

_canon_add_script_test(
    libraries.export-header-collision
    library/errors/test.cmake
    -DCANON_TEST_CASE=export-header-collision
    "-DCANON_EXPECTED_ERROR=generated export header 'canon_library_errors/foo_bar/export.hpp' for target 'second' conflicts with target 'first'"
)

_canon_add_script_test(
    libraries.export-macro-collision
    library/errors/test.cmake
    -DCANON_TEST_CASE=export-macro-collision
    "-DCANON_EXPECTED_ERROR=export macro 'AXIOM_CORE_API' for library 'AxiomCore::AxiomCore (target 'axiom_core_monolith')' conflicts with library 'Axiom::Core (target 'axiom_core')'"
)

_canon_add_script_test(
    dependencies.empty
    dependency/errors/test.cmake
    -DCANON_TEST_CASE=empty
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): package name must not be empty"
)

_canon_add_script_test(
    dependencies.required
    dependency/errors/test.cmake
    -DCANON_TEST_CASE=required
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): 'REQUIRED' is inherited"
)

_canon_add_script_test(
    dependencies.quiet
    dependency/errors/test.cmake
    -DCANON_TEST_CASE=quiet
    "-DCANON_EXPECTED_ERROR=canon_apply_dependency(): 'QUIET' is inherited"
)

_canon_add_script_test(
    dependencies.no-package
    dependency/errors/test.cmake
    -DCANON_TEST_CASE=no-package
    "-DCANON_EXPECTED_ERROR=package dependencies were declared, but project"
)
