# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Builds, installs, and consumes an application-shaped project that combines vendored and installed dependencies.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
set(_package_dir "${_prefix}/artifact-share/cmake/CanonApplicationFixture")

canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/application/project"
    BINARY "${_build}"
    ARGS -DCMAKE_INSTALL_LIBDIR=artifact-lib -DCMAKE_INSTALL_DATADIR=artifact-share
    EXPECTED_OUTPUT
        "finding dependency 'FixtureRuntime' - using vendored 'runtime'"
        "finding dependency 'FixtureGraphics' - using installed package 'FixtureGraphics'"
)
canon_test_build(BINARY "${_build}")
canon_test_execute(BINARY "${_build}" TARGET game)
canon_test_install(BINARY "${_build}" PREFIX "${_prefix}")
canon_test_check_install_manifest("${_build}" "${_prefix}")

set(_consumer "${CANON_TEST_BINARY_DIR}/package-consumer")
canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/application/package-consumer"
    BINARY "${_consumer}"
    ARGS "-DCanonApplicationFixture_DIR=${_package_dir}"
)
canon_test_build(BINARY "${_consumer}")
canon_test_execute(BINARY "${_consumer}" TARGET application_package_consumer)
