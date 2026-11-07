# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Runs the coverage lifecycle on a project, then proves its installed package carries the coverage runtime.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

# Place the project beneath an unrelated ancestor external/ directory. Only the project's own external/ is excluded.
set(_source "${CANON_TEST_BINARY_DIR}/source/external/coverage")
set(_build "${CANON_TEST_BINARY_DIR}/build")
set(_prefix "${CANON_TEST_BINARY_DIR}/install")
file(COPY "${CANON_SOURCE_DIR}/test/coverage/project/" DESTINATION "${_source}")
file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source}")

canon_test_configure(SOURCE "${_source}" BINARY "${_build}" ARGS -DCMAKE_INSTALL_LIBDIR=artifact-lib)

file(WRITE "${_build}/stale/stale.gcda" "deliberately invalid stale data")
canon_test_build(BINARY "${_build}" TARGET coverage-clean)
canon_test_forbid_paths("${_build}/stale/stale.gcda")

canon_test_build(BINARY "${_build}")
canon_test_ctest(BINARY "${_build}")
canon_test_build(BINARY "${_build}" TARGET coverage-report)

canon_test_read_files(_report "${_build}/coverage" index.html)
canon_test_require_matches("${_report}" "coverage report" "[\">/]covered\\.cpp")
canon_test_forbid_matches("${_report}" "coverage report" "covered_test\\.cpp" "excluded\\.cpp")
file(GLOB_RECURSE _remaining_data LIST_DIRECTORIES FALSE "${_build}/*.gcda")
canon_test_forbid_paths(${_remaining_data})

canon_test_install(BINARY "${_build}" PREFIX "${_prefix}")
set(_consumer "${CANON_TEST_BINARY_DIR}/package-consumer")
canon_test_configure(
    SOURCE "${CANON_SOURCE_DIR}/test/coverage/package-consumer"
    BINARY "${_consumer}"
    ARGS "-DCanonCoverageFixture_DIR=${_prefix}/artifact-lib/cmake/CanonCoverageFixture"
)
canon_test_build(BINARY "${_consumer}")
canon_test_execute(BINARY "${_consumer}" TARGET coverage_consumer)
