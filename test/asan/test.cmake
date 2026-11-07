# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Builds and runs instrumented targets, then proves an installed package carries the sanitizer runtime to consumers.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")

canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/asan"
    BINARY "${_build}"
    ARGS -DCMAKE_INSTALL_LIBDIR=artifact-lib
)
canon_test_build(BINARY "${_build}")
canon_test_execute(BINARY "${_build}" TARGET asan_app)
canon_test_ctest(BINARY "${_build}")
canon_test_install(BINARY "${_build}" PREFIX "${_prefix}")

set(_consumer "${CANON_TEST_BINARY_DIR}/package-consumer")
canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/asan/package-consumer"
    BINARY "${_consumer}"
    ARGS "-DCanonAsanFixture_DIR=${_prefix}/artifact-lib/cmake/CanonAsanFixture"
)
canon_test_build(BINARY "${_consumer}")
canon_test_execute(BINARY "${_consumer}" TARGET asan_static_consumer)
canon_test_execute(BINARY "${_consumer}" TARGET asan_shared_consumer)

canon_test_build(BINARY "${_build}" TARGET asan_probe)
canon_test_execute(
    BINARY "${_build}"
    TARGET asan_probe
    DESCRIPTION "AddressSanitizer reports a deliberate use after free"
    EXPECT_FAILURE
    EXPECTED_OUTPUT AddressSanitizer heap-use-after-free
)
