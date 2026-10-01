# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/asan"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCMAKE_INSTALL_LIBDIR=artifact-lib
    -DCANON_ENABLE_ASAN=ON
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

canon_test_run(
    DESCRIPTION "ASan configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "ASan build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
)
canon_test_run(
    DESCRIPTION "ASan executable"
    COMMAND "${CANON_TEST_BINARY_DIR}/asan_app"
)
canon_test_run(
    DESCRIPTION "ASan CTest run"
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --output-on-failure
)

set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
canon_test_run(
    DESCRIPTION "ASan install"
    COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}" --prefix "${_install_prefix}"
)

set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
set(_consumer_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/asan-package-consumer"
    -B "${_consumer_build_dir}"
    -G "${CANON_GENERATOR}"
    "-DCanonAsanFixture_DIR=${_install_prefix}/artifact-lib/cmake/CanonAsanFixture"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

canon_test_run(
    DESCRIPTION "ASan package consumer configure"
    COMMAND ${_consumer_configure_command}
)
canon_test_run(
    DESCRIPTION "ASan package consumer build"
    COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}"
)
foreach(_consumer IN ITEMS asan_static_consumer asan_shared_consumer)
    canon_test_run(
        DESCRIPTION "ASan package consumer '${_consumer}'"
        COMMAND "${_consumer_build_dir}/${_consumer}"
    )
endforeach()

canon_test_run(
    DESCRIPTION "ASan probe build"
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target asan_probe
)
canon_test_run(
    DESCRIPTION "AddressSanitizer invalid probe"
    EXPECT_FAILURE
    COMMAND "${CANON_TEST_BINARY_DIR}/asan_probe"
    EXPECTED_OUTPUT AddressSanitizer heap-use-after-free
)
