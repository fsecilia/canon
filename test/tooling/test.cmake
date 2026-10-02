# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_TEST_CASE
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

if ("${CANON_TEST_CASE}" STREQUAL "consumer")
    canon_test_require_variables(CANON_CLANG_TIDY_EXECUTABLE)

    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/tooling"
        -B "${CANON_TEST_BINARY_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCANON_ENABLE_WARNINGS=ON
        -DCANON_ENABLE_TIDY=ON
        "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    canon_test_run(
        DESCRIPTION "tidy configure"
        COMMAND ${_configure_command}
    )

    set(_nested_root "${CANON_TEST_BINARY_DIR}/nested-source")
    set(_nested_source_dir "${_nested_root}/external/tooling")
    set(_nested_binary_dir "${CANON_TEST_BINARY_DIR}/nested-build")
    file(MAKE_DIRECTORY "${_nested_root}/external")
    file(COPY "${CANON_SOURCE_DIR}/test/tooling/" DESTINATION "${_nested_source_dir}")
    file(COPY "${CANON_SOURCE_DIR}/test/support" DESTINATION "${_nested_root}/external")
    configure_file(
        "${CANON_SOURCE_DIR}/.clang-tidy"
        "${_nested_source_dir}/.clang-tidy"
        COPYONLY
    )

    set(_nested_configure_command
        "${CMAKE_COMMAND}"
        -S "${_nested_source_dir}"
        -B "${_nested_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCANON_ENABLE_WARNINGS=ON
        -DCANON_ENABLE_TIDY=ON
        "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _nested_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    canon_test_run(
        DESCRIPTION "tidy configure beneath ancestor external directory"
        COMMAND ${_nested_configure_command}
    )
    canon_test_run(
        DESCRIPTION "project header beneath ancestor external directory"
        EXPECT_FAILURE
        COMMAND "${CMAKE_COMMAND}" --build "${_nested_binary_dir}" --target tidy_header_probe
        EXPECTED_OUTPUT readability-identifier-naming
    )
    canon_test_run(
        DESCRIPTION "tidy build with managed external header"
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
    )
    canon_test_run(
        DESCRIPTION "deliberately invalid managed tidy target"
        EXPECT_FAILURE
        COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target tidy_probe
        EXPECTED_OUTPUT readability-identifier-naming
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "version")
    # Use CMake itself as a deterministic executable whose version is below the tidy floor.
    set(_unsupported_tidy "${CMAKE_COMMAND}")

    set(_consumer_binary_dir "${CANON_TEST_BINARY_DIR}/consumer")
    set(_consumer_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/tooling"
        -B "${_consumer_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCANON_ENABLE_TIDY=ON
        "-DCANON_CLANG_TIDY_EXECUTABLE=${_unsupported_tidy}"
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    canon_test_run(
        DESCRIPTION "configure with unsupported clang-tidy"
        EXPECT_FAILURE
        COMMAND ${_consumer_configure_command}
        EXPECTED_REGEX "requires clang-tidy 21\\.1\\.6 or newer"
    )

else()
    message(FATAL_ERROR "Unknown tooling test case '${CANON_TEST_CASE}'")
endif()
