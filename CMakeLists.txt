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
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

install(
    FILES
        cmake/Canon.cmake
        cmake/CanonConfig.cmake
        cmake/CanonCoverageClean.cmake
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

find_program(CANON_GCOVR_EXECUTABLE NAMES gcovr)
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    get_filename_component(_canon_compiler_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
    find_program(CANON_LLVM_COV_EXECUTABLE NAMES llvm-cov HINTS "${_canon_compiler_dir}")
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
            -P "${CMAKE_CURRENT_SOURCE_DIR}/test/scripts/${SCRIPT}"
    )
    set_tests_properties("canon.integration.${NAME}" PROPERTIES LABELS integration TIMEOUT 120)
endfunction()

_canon_add_script_test(
    targets
    target-consumer.cmake
    -DCANON_BUILD_TYPE=Debug
)

_canon_add_script_test(
    targets.release
    target-consumer.cmake
    -DCANON_BUILD_TYPE=Release
)

_canon_add_script_test(
    targets.warnings
    target-consumer.cmake
    -DCANON_BUILD_TYPE=Debug
    -DCANON_ENABLE_WARNINGS=ON
)

_canon_add_script_test(
    asan
    asan-consumer.cmake
)

set(_canon_coverage_test_arguments)
if (CANON_GCOVR_EXECUTABLE)
    list(APPEND _canon_coverage_test_arguments
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}")
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        if (CANON_LLVM_COV_EXECUTABLE)
            list(APPEND _canon_coverage_test_arguments
                "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
        else()
            set(_canon_coverage_test_arguments)
            message(STATUS "Canon coverage validation unavailable: llvm-cov was not found")
        endif()
    endif()
else()
    message(STATUS "Canon coverage validation unavailable: gcovr was not found")
endif()

if (_canon_coverage_test_arguments)
    _canon_add_script_test(
        coverage
        coverage-consumer.cmake
        ${_canon_coverage_test_arguments}
    )
endif()

if (CANON_CLANG_TIDY_EXECUTABLE)
    _canon_add_script_test(
        tidy
        tooling-consumer.cmake
        "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    )
else()
    message(STATUS "Canon clang-tidy validation unavailable: clang-tidy was not found")
endif()

if (Doxygen_FOUND)
    _canon_add_script_test(
        documentation
        documentation-consumer.cmake
        "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
    )
    _canon_add_script_test(
        documentation-warning
        documentation-warning.cmake
        "-DCANON_DOXYGEN_EXECUTABLE=${DOXYGEN_EXECUTABLE}"
    )
else()
    message(STATUS "Canon documentation validation unavailable: Doxygen 1.9 or newer was not found")
endif()

_canon_add_script_test(
    documentation-unavailable
    documentation-unavailable.cmake
)

_canon_add_script_test(
    vendored
    vendored-consumption.cmake
)

_canon_add_script_test(
    installed
    installed-consumption.cmake
    "-DCANON_EXPECTED_VERSION=${PROJECT_VERSION}"
)

_canon_add_script_test(
    presets.listings
    preset-listings.cmake
)

_canon_add_script_test(
    presets.debug
    preset-debug.cmake
)

_canon_add_script_test(
    presets.release
    preset-release.cmake
)

_canon_add_script_test(
    presets.asan
    preset-asan.cmake
)

if (_canon_coverage_test_arguments)
    _canon_add_script_test(
        presets.coverage
        preset-coverage.cmake
        ${_canon_coverage_test_arguments}
    )
endif()

if (CANON_CLANG_TIDY_EXECUTABLE)
    _canon_add_script_test(
        presets.tidy
        preset-tidy.cmake
        "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    )
endif()

_canon_add_script_test(
    targets.missing
    target-error.cmake
    -DCANON_TEST_CASE=missing
    "-DCANON_EXPECTED_ERROR=target 'missing' does not exist"
)

_canon_add_script_test(
    targets.interface
    target-error.cmake
    -DCANON_TEST_CASE=interface
    "-DCANON_EXPECTED_ERROR=target 'sample_interface' has type"
    "-DCANON_EXPECTED_DETAIL='INTERFACE_LIBRARY'"
)

_canon_add_script_test(
    libraries.missing
    library-missing-error.cmake
)

_canon_add_script_test(
    libraries.executable
    library-executable-error.cmake
)

_canon_add_script_test(
    libraries.object
    library-object-error.cmake
)

_canon_add_script_test(
    libraries.interface
    library-interface-error.cmake
)
