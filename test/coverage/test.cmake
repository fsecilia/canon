# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(CANON_SOURCE_DIR CANON_TEST_CASE)

if ("${CANON_TEST_CASE}" STREQUAL "backend-unavailable")
    canon_test_require_variables(
        CANON_TEST_BINARY_DIR
        CANON_CXX_COMPILER_ID
        CANON_CXX_COMPILER_FRONTEND_VARIANT
        CANON_CXX_COMPILER_VERSION
    )

    include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

    set(CMAKE_CXX_COMPILER "${CANON_TEST_BINARY_DIR}/missing-cxx-compiler")
    set(CMAKE_CXX_COMPILER_ID "${CANON_CXX_COMPILER_ID}")
    set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "${CANON_CXX_COMPILER_FRONTEND_VARIANT}")
    set(CMAKE_CXX_COMPILER_VERSION "${CANON_CXX_COMPILER_VERSION}")
    set(CANON_GCOV_EXECUTABLE "")
    set(CANON_LLVM_COV_EXECUTABLE "")

    _canon_find_coverage_backend(_backend)
    if (NOT "${_backend}" STREQUAL "")
        message(FATAL_ERROR
            "failed automatic coverage discovery unexpectedly produced '${_backend}'")
    endif()
    if (NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL ""
        OR NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        message(FATAL_ERROR
            "automatic coverage discovery populated an explicit override variable")
    endif()
    return()
endif()

if ("${CANON_TEST_CASE}" STREQUAL "backend")
    canon_test_require_variables(
        CANON_TEST_BINARY_DIR
        CANON_CXX_COMPILER_ID
        CANON_CXX_COMPILER_FRONTEND_VARIANT
        CANON_CXX_COMPILER_VERSION
    )

    include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")

    _canon_validate_coverage_version_output(
        "gcov (GCC) 14.3.0\n"
        GNU
        14
        _valid
        _reason
    )
    if (NOT _valid)
        message(FATAL_ERROR "matching GNU gcov version was rejected: ${_reason}")
    endif()

    _canon_validate_coverage_version_output(
        "gcov (GCC) 14.3.0\n"
        GNU
        15
        _valid
        _reason
    )
    if (_valid OR NOT "${_reason}" MATCHES "reports major version 14")
        message(FATAL_ERROR "GNU gcov major-version mismatch was not diagnosed")
    endif()

    _canon_validate_coverage_version_output(
        "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
        LLVM
        17
        _valid
        _reason
    )
    if (NOT _valid)
        message(FATAL_ERROR "matching LLVM llvm-cov version was rejected: ${_reason}")
    endif()

    _canon_validate_coverage_version_output(
        "LLVM (http://llvm.org/):\n  LLVM version 17.0.2\n"
        GNU
        17
        _valid
        _reason
    )
    if (_valid OR NOT "${_reason}" MATCHES "GNU gcov")
        message(FATAL_ERROR "coverage-tool family mismatch was not diagnosed")
    endif()

    _canon_resolve_reported_coverage_tool(
        canon-nonexistent-coverage-companion
        _resolved_executable
    )
    if (NOT "${_resolved_executable}" STREQUAL "")
        message(FATAL_ERROR
            "coverage discovery unexpectedly resolved '${_resolved_executable}' for a missing exact name")
    endif()

    canon_test_run(
        DESCRIPTION "coverage-backend unavailable probe"
        NORMALIZE_WHITESPACE
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
            "-DCANON_TEST_BINARY_DIR=${CANON_TEST_BINARY_DIR}"
            "-DCANON_CXX_COMPILER_ID=${CANON_CXX_COMPILER_ID}"
            "-DCANON_CXX_COMPILER_FRONTEND_VARIANT=${CANON_CXX_COMPILER_FRONTEND_VARIANT}"
            "-DCANON_CXX_COMPILER_VERSION=${CANON_CXX_COMPILER_VERSION}"
            -DCANON_TEST_CASE=backend-unavailable
            -P "${CANON_SOURCE_DIR}/test/coverage/test.cmake"
        EXPECTED_OUTPUT "did not report a usable"
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "override-error")
    canon_test_require_variables(
        CANON_TEST_BINARY_DIR
        CANON_GENERATOR
        CANON_CXX_COMPILER
        CANON_CXX_COMPILER_ID
    )

    if ("${CANON_CXX_COMPILER_ID}" STREQUAL "GNU")
        set(_override_variable CANON_GCOV_EXECUTABLE)
    elseif ("${CANON_CXX_COMPILER_ID}" STREQUAL "Clang")
        set(_override_variable CANON_LLVM_COV_EXECUTABLE)
    else()
        message(FATAL_ERROR "unsupported test compiler '${CANON_CXX_COMPILER_ID}'")
    endif()

    file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/coverage"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCANON_ENABLE_COVERAGE=ON
        "-D${_override_variable}=${CMAKE_COMMAND}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    canon_test_run(
        DESCRIPTION "invalid ${_override_variable} override"
        EXPECT_FAILURE
        COMMAND ${_configure_command}
        EXPECTED_OUTPUT
            "Canon coverage override ${_override_variable}="
            "invalid:"
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "nested")
    canon_test_require_variables(
        CANON_TEST_BINARY_DIR
        CANON_GENERATOR
        CANON_CXX_COMPILER
        CANON_GCOVR_EXECUTABLE
    )

    file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/coverage-nested"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCANON_ENABLE_COVERAGE=ON
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
    endif()

    canon_test_run(
        DESCRIPTION "nested coverage configure"
        COMMAND ${_configure_command}
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "consumer")
    canon_test_require_variables(
        CANON_TEST_BINARY_DIR
        CANON_GENERATOR
        CANON_CXX_COMPILER
        CANON_GCOVR_EXECUTABLE
    )

    set(_fixture_root "${CANON_TEST_BINARY_DIR}-fixture")
    set(_source_dir "${_fixture_root}/external/coverage")
    file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}" "${_fixture_root}")
    file(MAKE_DIRECTORY "${_source_dir}")
    file(COPY "${CANON_SOURCE_DIR}/test/coverage/" DESTINATION "${_source_dir}")

    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCMAKE_INSTALL_LIBDIR=artifact-lib
        -DCANON_ENABLE_COVERAGE=ON
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
    endif()

    canon_test_run(
        DESCRIPTION "coverage configure"
        COMMAND ${_configure_command}
    )

    file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}/stale")
    file(WRITE "${CANON_TEST_BINARY_DIR}/stale/stale.gcda" "deliberately invalid stale data")
    canon_test_run(
        DESCRIPTION "coverage clean"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-clean
    )
    if (EXISTS "${CANON_TEST_BINARY_DIR}/stale/stale.gcda")
        message(FATAL_ERROR "coverage-clean left stale profile data behind")
    endif()

    canon_test_run(
        DESCRIPTION "coverage build"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
    )
    canon_test_run(
        DESCRIPTION "coverage tests"
        COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --output-on-failure
    )

    canon_test_run(
        DESCRIPTION "coverage report"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target coverage-report
    )

    set(_index "${CANON_TEST_BINARY_DIR}/coverage/index.html")
    if (NOT EXISTS "${_index}")
        message(FATAL_ERROR "coverage-report did not generate ${_index}")
    endif()
    file(READ "${_index}" _html)
    if (NOT "${_html}" MATCHES "covered\\.cpp")
        message(FATAL_ERROR "coverage report does not contain covered.cpp")
    endif()
    if ("${_html}" MATCHES "covered_test\\.cpp")
        message(FATAL_ERROR "coverage report unexpectedly contains covered_test.cpp")
    endif()
    if ("${_html}" MATCHES "excluded\\.cpp")
        message(FATAL_ERROR "coverage report unexpectedly contains external/excluded.cpp")
    endif()

    file(GLOB_RECURSE _remaining_gcda LIST_DIRECTORIES FALSE "${CANON_TEST_BINARY_DIR}/*.gcda")
    if (_remaining_gcda)
        message(FATAL_ERROR "coverage-report left .gcda files behind: ${_remaining_gcda}")
    endif()

    set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
    canon_test_run(
        DESCRIPTION "coverage install"
        COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}" --prefix "${_install_prefix}"
    )

    set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
    set(_consumer_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/coverage-package-consumer"
        -B "${_consumer_build_dir}"
        -G "${CANON_GENERATOR}"
        "-DCanonCoverageFixture_DIR=${_install_prefix}/artifact-lib/cmake/CanonCoverageFixture"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    canon_test_run(
        DESCRIPTION "coverage package consumer configure"
        COMMAND ${_consumer_configure_command}
    )
    canon_test_run(
        DESCRIPTION "coverage package consumer build"
        COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}"
    )
    canon_test_run(
        DESCRIPTION "coverage package consumer"
        COMMAND "${_consumer_build_dir}/coverage_consumer"
    )
else()
    message(FATAL_ERROR "Unknown coverage test case '${CANON_TEST_CASE}'")
endif()
